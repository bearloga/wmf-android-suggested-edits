# Sys.setenv("RETICULATE_PYTHON" = "~/envs/data-analysis/bin/python") # locally
Sys.setenv("RETICULATE_PYTHON" = "~/venv/bin/python") # on notebook1004

library(glue)
library(purrr)
library(reticulate)
library(ratelimitr)

# columns: rev_date, rev_ts, rev_id, page_id, rev_user, edit_type, reverted, reverting_rev
revert_status_data <- readr::read_csv("revert_status_data.csv.gz", col_types = "DTiiicli")

# figure out which revs to fetch:
start_date <- min(
  Sys.Date() - 3, # start at least 2 days before yesterday
  max(revert_status_data$rev_date) # or earlier
)
end_date <- Sys.Date() # fetch revisions up to yesterday
message(
  "re-checking status of ",
  nrow(dplyr::filter(revert_status_data, rev_date >= start_date)),
  " edits, in addition to ones that have been posted since ",
  max(revert_status_data$rev_date)
)

# pip install -U mwapi mwreverts jsonable mwtypes
mwapi <- import("mwapi")
mwrev <- import("mwreverts")

start_yyyymmdd <- format(start_date, "%Y%m%d")
end_yyyymmdd <- format(end_date, "%Y%m%d")
mw_query <- glue("SELECT
  rev_id, rev_page AS page_id, rev_user AS user_id, rev_timestamp,
  IF(INSTR(rev_comment, '#suggestededit') > 0 OR INSTR(comment_text, '#suggestededit') > 0, 'suggested', 'regular') AS edit_type
FROM revision
LEFT JOIN revision_comment_temp rct ON revision.rev_id = rct.revcomment_rev
LEFT JOIN `comment` ON rct.revcomment_comment_id = `comment`.comment_id
LEFT JOIN change_tag ON revision.rev_id = change_tag.ct_rev_id
WHERE rev_timestamp >= '${start_yyyymmdd}' AND rev_timestamp < '${end_yyyymmdd}'
  AND rev_user > 0 -- anonymous edits
  AND NOT rev_deleted
  AND ct_tag_id = 14 -- android app edit", .open = "${")

# description_edits <- readr::read_csv("query_result.csv", col_types = "iiicc")
description_edits <- wmf::mysql_read(mw_query, "wikidatawiki") %>%
  dplyr::mutate_if(is.numeric, as.integer) %>%
  dplyr::as_tibble()
# readr::write_csv(description_edits, "query_result.csv")

description_edits <- description_edits %>%
  dplyr::mutate(
    rev_ts = lubridate::ymd_hms(rev_timestamp),
    rev_date = as.Date(rev_ts)
  )

# Create MW API session:
api_session = mwapi$Session("https://www.wikidata.org", user_agent = "Revert detection <mpopov@wikimedia.org>")

check_rev <- function(rev_id, page_id) {
  # docs: https://pythonhosted.org/mwreverts/api.html
  response <- mwrev$api$check(api_session, rev_id = rev_id, page_id = page_id, radius = 5, window = 48 * 60 * 60)[[2]]
  return(response)
}
# max 10 calls per second, 500 calls per minute
check_rev_limited <- limit_rate(check_rev, rate(n = 10, period = 1), rate(n = 300, period = 60))

# Process revisions day-by-day:
description_edits_by_date <- split(description_edits, description_edits$rev_date)
dates <- names(description_edits_by_date)
revert_status <- vector(mode = "list", length = length(dates)) %>%
  set_names(dates)
for (d in dates) {
  message("checking revert status of ", nrow(description_edits_by_date[[d]]), " edits made on ", d)
  rev_ids <- description_edits_by_date[[d]]$rev_id %>% set_names(., .)
  page_ids <- description_edits_by_date[[d]]$page_id
  revert_status[[d]] <- purrr::map2(rev_ids, page_ids, check_rev_limited)
}

# Wrangle into the format we want:
rev_status <- purrr::map_dfr(revert_status, function(revisions) {
  return(purrr::map_dfr(revisions, function(revision) {
    if (!is.null(revision)) {
      return(data.frame(reverted = TRUE, reverting_rev = revision$reverting$revid))
    } else {
      return(data.frame(reverted = FALSE, reverting_rev = as.integer(NA)))
    }
  }, .id = "rev_id"))
}) %>% dplyr::mutate(rev_id = as.integer(rev_id))

# Augment the existing data with newly fetched data:
rs_df <- dplyr::left_join(description_edits, rev_status, by = "rev_id") %>%
  dplyr::bind_rows(dplyr::filter(revert_status_data, rev_date < start_date))
# And then save it:
rs_df %>%
  dplyr::arrange(rev_date, rev_timestamp, rev_id) %>%
  dplyr::select(rev_date, rev_ts, rev_id, page_id, user_id, edit_type, reverted, reverting_rev) %>%
  readr::write_csv("revert_status_data.csv")
system("gzip --force revert_status_data.csv") # compress
