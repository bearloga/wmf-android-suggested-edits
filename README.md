# Daily report of Suggested Edits v1 release on Android

On **notebook1004.eqiad.wmnet** `mkdir /srv/published-datasets/wikipedia-android-app-reports` if one does not already exist.

Then `crontab -e`:

```
0 5 * * * bash /home/bearloga/android/suggested_edits/update_publish_notebook.sh
```

to have the script be executed every day at 5AM UTC.
