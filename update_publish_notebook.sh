#!/bin/bash
cd /home/bearloga/android/suggested_edits
{
  date
  
  echo "Fetching revert status of title descriptions"
  Rscript revert_rate_title-descriptions.R
  
  # echo "Refreshing report v1"
  # /home/bearloga/venv/bin/jupyter nbconvert --ExecutePreprocessor.timeout=900 --execute --to html suggested-edits-v1.ipynb
  # cp suggested-edits-v1.html /srv/published-datasets/wikipedia-android-app-reports
  
  echo "Fetching revert status of image captions"
  Rscript revert_rate_image-captions.R
  
  echo "Refreshing report v2"
  /home/bearloga/venv/bin/jupyter nbconvert --ExecutePreprocessor.timeout=900 --execute --to html suggested-edits-v2.ipynb
  cp suggested-edits-v2.html /srv/published-datasets/wikipedia-android-app-reports

} >> /home/bearloga/android/suggested_edits/notebook_update.log 2>&1
