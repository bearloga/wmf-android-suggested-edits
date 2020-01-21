#!/bin/bash
SE_PATH=/home/bearloga/android/suggested_edits
PYTHON_HOME=/home/bearloga/venv/bin

cd $SE_PATH
{
  date

  echo "Fetching revert status of title descriptions"
  Rscript revert_rate_title-descriptions.R

  echo "Fetching revert status of image captions"
  Rscript revert_rate_image-captions.R

  echo "Refreshing report v2"
  $PYTHON_HOME/jupyter nbconvert --ExecutePreprocessor.timeout=900 --execute --to html suggested-edits-v2.ipynb
  cp suggested-edits-v2.html /srv/published-datasets/wikipedia-android-app-reports

} >> $SE_PATH/notebook_update.log 2>&1
