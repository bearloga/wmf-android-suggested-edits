# Daily report of Suggested Edits v2 release on Android

## Setup

### Python dependencies

First, we need to make sure the Jupyter notebook will be run and converted to HTML correctly:

```bash
pip install -U pip setuptools nbconvert ipython ipykernel \
  jupyter jupyter-core jupyter-console jupyter-core jupyter-client jupyterlab
```

Then, we need to install MediaWiki utilities for obtaining the revert rate of title descriptions and image captions:

```bash
pip install -U mwoauth mwtypes mwapi mwreverts
```

### R dependencies

Following [these instructions](https://irkernel.github.io/installation/) for installing the R kernel and registering it with Jupyter:

```R
install.packages("IRkernel")
IRkernel::installspec()
```

Then the packages required for producing the report:

```R
install.packages(c(
  "RMySQL", "DBI", "tidyverse", "import", "knitr", "remotes",
  "reticulate", # for using MediaWiki Python utils
  "ratelimitr", # for throttling MW API calls
  "RcppRoll",   # for smoothing using rolling average
  "hrbrthemes"  # for pretty plots
))
remotes::install_github("wikimedia/wikimedia-discovery-wmf")
remotes::install_github("wikimedia/wikimedia-discovery-polloi")
remotes::install_github("thomasp85/patchwork")
```

## Scheduling

On **notebook1004.eqiad.wmnet** `mkdir /srv/published-datasets/wikipedia-android-app-reports` if one does not already exist.

Then `crontab -e`:

```
0 5 * * * bash /path/to/update_publish_notebook.sh
```

to have the script be executed every day at 5AM UTC (for example).
