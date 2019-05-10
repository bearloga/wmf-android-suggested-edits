#!/bin/bash
cd /home/bearloga/android/suggested_edits
{
  date
  Rscript revert_rate.R
  /home/bearloga/venv/bin/jupyter nbconvert --ExecutePreprocessor.timeout=900 --execute --to html suggested-edits-v1.ipynb
  cp suggested-edits-v1.html /srv/published-datasets/wikipedia-android-app-reports
} >> /home/bearloga/android/suggested_edits/notebook_update.log 2>&1
