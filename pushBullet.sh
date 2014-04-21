#! /bin/bash

# Bash interface to the PushBullet api.

# Author: Red5d - https://github.com/Red5d

CONFIG=~/.config/pushbullet
API_URL=https://api.pushbullet.com/api

source $CONFIG

printUsage() {
echo "Usage: pushbullet <action> <device> <type> <data>

Actions: 
list - Lists all devices in your PushBullet account. (does not require
       additional parameters)
push - Pushes data to a device. (the device name can simply be a unique part of
       the name that \"list\" returns)

Types: 
note
address
list
file
link

Type Parameters: 
(all parameters must be put inside quotes if more than one word)
\"note\" type: 	give the title, then the note text.
\"address\" type: give the address name, then the address or Google Maps query.
\"list\" type: 	give the name of the list, then each of the list items,
                seperated by spaces.
\"file\" type: 	give the path to the file.
\"link\" type: 	give the title of the link, then the url.
"
}


if [ "$1" = "" ];then

if [ "$API_KEY" = "" ];then
echo -e "\e[0;33mWarning, your API key is not set.\nPlease create $CONFIG with a line starting with API_KEY= and your PushBullet key\e[00m"
fi

printUsage
exit
fi

case $1 in
list)
	echo "Available devices:"
	echo "------------------"
	curl -s "$API_URL/devices" -u $API_KEY: | tr ',' '\n' | grep model | cut -d '"' -f4
	;;
push)

	devices=$(curl -s "$API_URL/devices" -u $API_KEY: | tr '{' '\n' | tr ',' '\n' | grep model | cut -d'"' -f4)
	idens=$(curl -s "$API_URL/devices" -u $API_KEY: | tr '{' '\n' | tr ',' '\n' | grep iden | cut -d'"' -f4)
	lineNum=$(echo "$devices" | grep -i -n $2 | cut -d: -f1)
	dev_id=$(echo "$idens" | sed -n $lineNum'p')
	if [ $2 = "all" ];then
		dev_id=$API_KEY
	fi

	case $3 in
	note)

		curl -s "$API_URL/pushes" -u $API_KEY: -d device_iden=$dev_id -d type=note -d title="$4" -d body="$5" -X POST| grep -o "created" | tail -n1

	;;

	address)

		curl -s "$API_URL/pushes" -u $API_KEY: -d device_iden=$dev_id -d type=address -d name="$4" -d address="$5" -X POST | grep -o "created" | tail -n1

	;;

	list)

	 argnum=0
        for i in $@
        do
          let argnum=$argnum+1
          if [ $argnum -ge 5 ];then
            itemlist=$itemlist" -d items=$i"
          fi
        done
	curl -s $API_URL/pushes -u $API_KEY: -d device_iden=$dev_id -d type=list -d title=$4 $itemlist -X POST | grep -o "created" | tail -n1

	;;

	file)

		curl -s "$API_URL/pushes" -u $API_KEY: -F device_iden=$dev_id -F type=file -F file="@$4" -X POST | grep -o "created" | tail -n1

	;;

	link)

		curl -s "$API_URL/pushes" -u $API_KEY: -d device_iden=$dev_id -d type=link -d title="$4" -d url="$5" -X POST | grep -o "created" | tail -n1

	;;
	esac

;;

*)
  printUsage
;;
esac
