downloadNightlies
=================

Downloads nightly releices for CyanogenMod for any model(s) and shoves them into DropBox.  Designed to be run as a cron job or from the terminal with no output unless there's a problem.

Functions
=========
The basic idea is that it goes and scrapes the CM download site for an update.  If it finds one, it does the following things:

1.  Downloads the update file.
2.  Upload the file to DropBox.
3.  Moves the file into place in the local Dropbox folder.
4.  Pushes out a notice saying the update was found and downloaded.

Version History
===============
This is the initial release to GitHub.

v0.1
====
Initial download script.
Uses a beta URL (http://beta.get.cm/?device=id) which redirects to the real download URL.

v0.2
====
Grabs the URL, checks it against the current date, and only downloads something new.
Sends out SMS via Google Voice API.

v0.2 rev a
==========
Correct bug in SMS sending via Google Voice.

v0.3
====
Added upload script to send updates to DropBox (dropboxUploader.py).

v0.3 rev a
==========
Fix computer downloading the updates again from DropBox once user logs into desktop environment.
Change from python uploader script for DropBox to bash script (dropbox_uploader.sh).
Correct another bug in sending SMS via Google Voice.

v0.4
====
Complete rewrite, beta URL shut down.  Now scrape the main download page for update.
Correct more problems with sending SMS via Google Voice.
Correct problems with downloads not completeing properly but files saved anyway.
Add semiphore files so that the script doesn't even call out to the web if an update has already been downloaded.
Add semiphore file so that if the script is still running and it tries to run again, silently exits.
Add testing mode (-t) to see command line output, progress bars, and debugging information.

v0.4 rev a
==========
Ditch Google Voice API, begin using PushOver API & App

v0.4 rev b
==========
Add clean mode (-c) to clean up all semiphore files.
Change working directory from /tmp, OS was sometimes deleting files before they could upload.

v0.5
====
Another complete rewrite, code was messy.  Using subroutines makes it a lot cleaner.
Made changing the options friendly (variables in the top of the file).

v0.5 rev a
==========
Started using push bullet support (http://www.pushbullet.com), the service and apps are free.
Added pushBullet.sh script.

v0.5 rev b
==========
Tweaked pushBullet.sh to add option to send note to all devices.
Uploaded everything to github repo.
