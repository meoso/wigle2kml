#!/bin/bash

#Check for at least 2 arguments
if [ $# -lt 1 ] ; then
	echo
	echo "$0 - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe"
	echo 
	echo "Usage: $0 zip [\"[-v] filter[|filter[|filter]]\"]"
	echo
	echo "Outputs: zip_filtered.txt and zip_filtered.kml files"
	echo 
	echo "Dependencies: egrep"
	echo
	echo "Parameters:"
	echo "zip - required; 5-digit U.S. postal-code only ; reads local zip.txt file"
	echo "filter: optional ; however, quotes (\"\") are required around filter list; passed verbatim to egrep, so -v is inverse"
	echo
	echo "example usage: $0 47150 \"linksys\""
	echo "example usage: $0 47150 \"-v MIFI|HP-Print|2WIRE\""
	echo
	exit 1
fi

zip=$1

if [[ -z $2 ]]
then 
	filter=""
else
	filter=$2
fi


function populateKMLfolder () {
	enc=$1
	folder=$2
	echo "Processing Enc=$enc ($folder)"

 	case $enc in
		"Y")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wep.png"
			;;
		"N")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/open.png"
			;;
		"W")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wpa.png"
			;;
		"2")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wpa2.png"
			;;
		*)
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/unknown.png"
	esac

	echo "<Folder><name>$folder</name><open>0</open>" >> "${zip}"_filtered.kml

	#as of Nov 2014: 18 elements (0-17)
	#  0     1     2     3     4     5      6       7         8       9   10   11      12      13       14       15       16     17
	#netid~ssid~comment~name~type~freenet~paynet~firsttime~lasttime~flags~wep~trilat~trilong~lastupdt~channel~bcninterval~qos~userfound
	fileline=0 #debug
	while read line ; do
		fileline=$((fileline+1)) #debug
		IFS='~' read -a array <<< "$line"
		#echo "file-line $fileline: ${array[0]} ${array[1]} ${array[10]}" #debug

		if [[ "${#array[@]}" -eq "18" ]] && [[ "${array[10]}" == "$enc" ]]  #needed == instead of -eq due: syntax error: operand expected (error token is "?")
		then
			echo "<Placemark>" >> "${zip}"_filtered.kml
			echo "	<description>" >> "${zip}"_filtered.kml
			echo "		<![CDATA[" >> "${zip}"_filtered.kml
			echo "			SSID: $array[0] <BR>" >> "${zip}"_filtered.kml
			echo "			BSSID: ${array[1]} <BR>" >> "${zip}"_filtered.kml
			echo "			TYPE: ${array[4]} <BR>" >> "${zip}"_filtered.kml
			echo "			ENCRYPTION: ${array[10]} <BR>" >> "${zip}"_filtered.kml
			echo "			CHANNEL: ${array[14]} <BR>" >> "${zip}"_filtered.kml
			echo "			QOS: ${array[16]} <BR>" >> "${zip}"_filtered.kml
			echo "			Last Seen: ${array[13]} <BR>" >> "${zip}"_filtered.kml
			echo "			Latitude: ${array[11]} <BR>" >> "${zip}"_filtered.kml
			echo "			Longitude: ${array[12]} <BR>" >> "${zip}"_filtered.kml
			echo "		]]>" >> "${zip}"_filtered.kml
			echo "	</description>" >> "${zip}"_filtered.kml
			echo "	<name><![CDATA[${array[1]}]]></name>" >> "${zip}"_filtered.kml
			echo "	<Style>" >> "${zip}"_filtered.kml
			echo "		<IconStyle>" >> "${zip}"_filtered.kml
			echo "		<Icon>;" >> "${zip}"_filtered.kml
			echo "			<href>$iconwep</href>" >> "${zip}"_filtered.kml
			echo "		</Icon>" >> "${zip}"_filtered.kml
			echo "		</IconStyle>" >> "${zip}"_filtered.kml
			echo "	</Style>" >> "${zip}"_filtered.kml
			echo "	<Point id=\"$folder_${array[0]}\">" >> "${zip}"_filtered.kml
			echo "		<coordinates>${array[12]},${array[11]}</coordinates>" >> "${zip}"_filtered.kml
			echo "	</Point>" >> "${zip}"_filtered.kml
			echo "</Placemark>" >> "${zip}"_filtered.kml
		fi
	done <"$zip"_filtered.txt

	echo "</Folder>" >> "${zip}"_filtered.kml
} ##END function










#MAIN
if [ -f "$zip".txt ]
then

	# apply filter if one was provided (ignorant of fields -- whole-line filtering)
	if ! [[ -z $filter ]]
	then 
		egrep $filter "$zip".txt > "$zip"_filtered.txt
	else 
		cp "$zip".txt "$zip"_filtered.txt
	fi

	#cat "$zip".txt #debug
	echo

	#open new kml
	echo '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Folder><name>WiGLE Data</name><open>1</open>' > "${zip}"_filtered.kml

	populateKMLfolder "N" "Open"
	populateKMLfolder "Y" "WEP"
	populateKMLfolder "W" "WPA"
	populateKMLfolder "2" "WPA2"
	populateKMLfolder "?" "Unknown"

	#close kml
	echo '</Folder></kml>' >> "${zip}"_filtered.kml
	echo "Finished: files created: "$zip"_filtered.txt and "${zip}"_filtered.kml"
	echo
else
	echo "$zip".txt not found.
	exit 1
fi

exit 0
