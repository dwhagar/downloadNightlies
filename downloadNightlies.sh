#!/bin/bash

# Shell script to download latest nightly into DropBox.
#   Usage:  downloadNightlies.sh [-t|-m]
#
#   -t = Testing mode, verbose output.
#   -c = Cleanup from a failed download attempt, removes all semaphore files.
#

######################################################################################
### Set customization variables here, of particular importance are the directories ###
### and the API/User key for the push notifications.                               ###
######################################################################################

# Set all the other variables we are going to need.
# This is where DropBox is stored on your hard disk.
dropBox="/Users/cyclops/Dropbox/"

# Where the required script files are located.  The trailing / is purposefully left
# off so that it is easier to read when this script calls any others.
scriptLocation=$dropBox"Scripts"

# This is where the updates will be stored relative to the DropBox root.
insideDropBox="Android/CyanogenMod/"

# The phone & tablet designations found at CyanogenMod's download site, this is not
# supposed to be "Samsung Galaxy S3 Verizon" but instead that would be d2vzw.  There
# should be an array entry for every device you'll need to check for an update.
id=( "n5110" )

# Using pushbullet now, pushBullet.sh can be found at:
# https://github.com/Red5d/pushbullet-bash

# PushOver Keys to send the notifications.
#userKey="uXiQtV1uyjLVdsEJ2Sh7ftVwZWq1W5"
#APIKey="a4MQuUoAoavZD9QTYnAPdtgFGUbwTc"
#pushURL="https://api.pushover.net/1/messages.json"

#####################################################################################
### Probably shouldn't alter anything below this line unless you have to and know ###
### what you are doing.                                                           ###
#####################################################################################

# Set where we are going to do the download to your local disk.
cd ~/.tmp

[[ $# -eq 0 ]] && testing="No"

case "$1" in
"-t"|"/t")
  testing="Yes"
  echo Testing mode...  Will show command outputs as well as debuggning information.
  echo ;;
"-c"|"/c")
  rm .download*
  exit ;;
*)
  testing="No" ;;
esac

# If you find a semaphore, exit immediately, the script is running.
# If you don't find the semaphore, create one and continue.
[[ -f .downloadNightlies.running ]] && exit 0 || echo "Running" > .downloadNightlies.running

[[ $testing == "Yes" ]] && pushMessage="This is an example of a push notification message."
 
# Current date to compare to.
currentDate=$(date +"%Y%m%d")

# Check for an update to a device, if one is found then download it.
# Status codes:
# 0 = update found & downloaded
# 1 = either no update found or download failed.
# 2 = already downloaded, check again tomorrow.

# Usage:  checkUpdate $deviceID $devicePath
function checkUpdate {
	# Make more readable variable names from the input.
	deviceID=$1
	devicePath=$2
	
	# To build the URL to get the redirect from.
	sitePrefix="http://download.cyanogenmod.com/?device="
	downloadPrefix="http://get.cm"
	
	# Check for device download semaphore file.
	if [[ -f .downloaded.$deviceID.$currentDate ]] ; then
		if [[ $testing == "Yes" ]] ; then
			echo Semaphore file found for $deviceID not looking further.
		fi
		return 2
	else
		rm .downloaded.$deviceID.* >& /dev/null
	fi

	# Find out if there actually is an update or not.
	updateRedirect=$(curl -s $sitePrefix$deviceID |grep a\ href\=\"/get/jenkins| grep $currentDate| awk -F\" '{ print $2 }')
	updateRedirect=$downloadPrefix$updateRedirect
	updateFile=$(echo $updateRedirect | awk -F "/" 'NF > 1 { print $(NF); }')
	if [[ -f $devicePath$updateFile || $updateRedirect == $downloadPrefix ]] ; then
		# No update found / update found already in place.
		if [[ $testing == "Yes" ]] ; then
			echo Update found already downloaded for $deviceID or no update available, stopping.
		fi
		return 1
	else
		if [[ $testing == "Yes" ]] ; then
			echo Update located for $deviceID downloading using the following command:
			echo curl -\# -L -f -O $updateRedirect
			curl -\# -L -f -O $updateRedirect
			echo
			echo Directory listing to see if download was correctly done.
			ls -lh cm*.zip
			echo
		else
			curl -s -L -f -O $updateRedirect
		fi
		if [[ $(stat -f%z $updateFile) -ge 183500000 ]] ; then
			# Update downloaded successfully.  Create semaphore file to prevent further
			# checking until tomorrow.
			echo Downloaded > .downloaded.$deviceID.$currentDate
			return 0
		else
			# Update failed to properly download.
			if [[ $testing == "Yes" ]] ; then
				echo Update failed to properly download, here is a directory listing for debugging.
				echo The file should be listed along with its size, which should be over 175Mb.
				ls -lh cm*.zip
			fi
			rm $updateFile >& /dev/null
			return 1
		fi
	fi
}

# Upload the file to DropBox and move the local file from the working directory
# into the DropBox local folder so it doesn't get downloaded again when the machine
# starts up and runs the desktop client for DropBox.

# Usage:  uploadFile $uploadPath $updateFile $localDropBox $deviceID
function uploadFile {
	# Assign variables readable names.
	uploadPath=$1 # This is relative to DropBox root.
	updateFile=$2
	localDropBox=$3 # Destination of where on the local disk the file is to be moved
	                # relative to disk root.
	deviceID=$4 # To remove semaphore file created earlier if for some reason the
                    # file goes missing before we can get it uploaded.
                    
	if [[ ! -f $updateFile ]] ; then
		if [[ $testing == "Yes" ]] ; then
			echo Trying to upload but file $updateFile not found.
		fi
		rm .downloaded.$deviceID.$currentDate
		return 1
	fi

	# Send the file to DropBox
	if [[ $testing == "Yes" ]] ; then
		$scriptLocation/dropbox_uploader.sh upload $updateFile $uploadPath
	else
		$scriptLocation/dropbox_uploader.sh -q upload $updateFile $uploadPath
	fi
	
	mv $updateFile $localDropBox >& /dev/null
	return 0
}

# Sends a notification that an update was found, downloaded, and sent to DropBox.

# Usage:  sendNotice $message
function sendNotice {
	# Assign variables readable names.
	message=$1
	
    if [[ $testing == "No" ]] ; then
    	# Send the push notification message.
    	~/Dropbox/Scripts/pushBullet.sh push all note "CyanogenMod Nightly Available" "$message" > /dev/null
    else
    	# Or, if testing, just display the message.
    	echo $message
        echo
    fi
}

# Walk through the array of devices and get updates for each, if they are available.
for device in "${id[@]}"
do
	checkUpdate $device $dropBox$insideDropBox$device"/"
	if [[ $? -eq 0 ]] ; then
		uploadFile $insideDropBox$device $updateFile $dropBox$insideDropBox$device $device
		if [[ $? -eq 0 ]] ; then
			sendNotice "Update for "$device" found.  File "$updateFile" downloaded and has been sent to DropBox."
		fi
	fi
done

# Delete the semaphore, execution is complete.
rm .downloadNightlies.running
