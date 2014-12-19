#!/bin/bash

#Check for at least 4 arguments
if [ $# -lt 4 ] ; then
	echo
	echo "	$0 - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe"
	echo
	echo "	Usage: $0 username zipcode variance lastseen [\"[-v] filter[|filter[|filter]]\"]"
	echo
	echo "	Dependencies: curl, bc, grep, egrep, awk, WiGLE.net account"
	echo "	Automatically downloads http://www.unitedstateszipcodes.org/zip_code_database.csv"
	echo "	Using api reference: http://www5.musatcha.com/musatcha/computers/wigleapi.htm"
	echo
	echo "	zipcode: 5-digit U.S. postal-code only"
	echo "	variance: small decimal number (0.01 to 0.2); example 0.03"
	echo "	lastseen: in the form of YYYYMMDDHHMMSS; example 20140101000000"
	echo "	filter: optional parameter; however, quotes (\"\") are required around filter list; passed verbatim to egrep, so -v is inverse"
	echo "	example: $0 irongeek 47150 0.03 20140101000000 \"linksys\""
	echo "	example: $0 irongeek 47150 0.03 20140101000000 \"-v MIFI|HP-Print|2WIRE\""
	echo
	exit 1
fi

username=$1
zip=$2
var=$3
lastupdt=$4
if [[ -z $1 ]]
then 
	filter=""
else
	filter=$5
fi


if ! [ -f zip_code_database.csv ]
then
	echo Downloading zip_code_database.csv
	curl -O http://www.unitedstateszipcodes.org/zip_code_database.csv
fi

#Since the csv also has quotes, let's reform it using ↈ as the delimiter, but keeping the commas inside the previously quoted field values.
if ! [ -f NEW_ZIP.csv ]
then
   cat zip_code_database.csv | sed 's/\",\"/ↈ/g' | sed 's/,\"/ↈ/g' | sed 's/\",/ↈ/g' | sed 's/\"//g' | sed 's/ↈ,/ↈↈ/g' | sed 's/,ↈ/ↈↈ/g' | sed 's/,,/ↈↈ/g' > NEW_ZIP.csv
fi

line=""
line=$(grep ^$zip NEW_ZIP.csv)

if [ "${line}" == "" ]
then
	echo Zip $zip not found.
	exit 1
fi

IFS=ↈ read -a array <<< $line

lat=${array[9]}
long=${array[10]}

echo
echo Zip:$zip
echo Lat:$lat
echo Long:$long
echo Variance:$var

latrange1=$(echo "$lat-$var" | bc)
latrange2=$(echo "$lat+$var" | bc)
longrange1=$(echo "$long-$var" | bc)
longrange2=$(echo "$long+$var" | bc)

echo "Calculated range: ($latrange1,$longrange1) to ($latrange2,$longrange2)"

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

	echo "<Folder><name>$folder</name><open>0</open>" >> $zip.kml

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
			echo "<Placemark>" >> $zip.kml
			echo "	<description>" >> $zip.kml
			echo "		<![CDATA[" >> $zip.kml
			echo "			SSID: $array[0] <BR>" >> $zip.kml
			echo "			BSSID: ${array[1]} <BR>" >> $zip.kml
			echo "			TYPE: ${array[4]} <BR>" >> $zip.kml
			echo "			ENCRYPTION: ${array[10]} <BR>" >> $zip.kml
			echo "			CHANNEL: ${array[14]} <BR>" >> $zip.kml
			echo "			QOS: ${array[16]} <BR>" >> $zip.kml
			echo "			Last Seen: ${array[13]} <BR>" >> $zip.kml
			echo "			Latitude: ${array[11]} <BR>" >> $zip.kml
			echo "			Longitude: ${array[12]} <BR>" >> $zip.kml
			echo "		]]>" >> $zip.kml
			echo "	</description>" >> $zip.kml
			echo "	<name><![CDATA[${array[1]}]]></name>" >> $zip.kml
			echo "	<Style>" >> $zip.kml
			echo "		<IconStyle>" >> $zip.kml
			echo "		<Icon>;" >> $zip.kml
			echo "			<href>$iconwep</href>" >> $zip.kml
			echo "		</Icon>" >> $zip.kml
			echo "		</IconStyle>" >> $zip.kml
			echo "	</Style>" >> $zip.kml
			echo "	<Point id=\"$folder_${array[0]}\">" >> $zip.kml
			echo "		<coordinates>${array[12]},${array[11]}</coordinates>" >> $zip.kml
			echo "	</Point>" >> $zip.kml
			echo "</Placemark>" >> $zip.kml
		fi
	done <$zip.txt

	echo "</Folder>" >> $zip.kml
} ##END function


echo
read -s -p "Password for WiGLE.net user $username:" password

#successful login will result in 302
result=$(curl -s -c cookie.txt -d "credential_0=$username&credential_1=$password&noexpire=off" https://wigle.net/gps/gps/GPSDB/login/ | grep 302)

# if no error (if successful 302)
if [[ $? == 0 ]]
then 
	echo "Downloading data:"
	curl -b cookie.txt -o $zip.txt "https://wigle.net/gpsopen/gps/GPSDB/confirmquery?longrange1=$longrange1&longrange2=$longrange2&latrange1=$latrange1&latrange2=$latrange2&simple=true&lastupdt=$lastupdt"

	# apply filter if one was provided (ignorant of fields -- whole-line filtering)
	if ! [[ -z $filter ]]
	then 
		egrep $filter $zip.txt > filter.txt
		mv filter.txt $zip.txt
	fi

	#cat $zip.txt #debug
	echo

	#open new kml
	echo '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Folder><name>WiGLE Data</name><open>1</open>' > $zip.kml

	populateKMLfolder "N" "Open"
	populateKMLfolder "Y" "WEP"
	populateKMLfolder "W" "WPA"
	populateKMLfolder "2" "WPA2"
	populateKMLfolder "?" "Unknown"

	#close kml
	echo '</Folder></kml>' >> $zip.kml
	echo "Finished: files created: $zip.txt and $zip.kml"
	echo
else
	echo "failed to authenticate."
	exit 1
fi

exit 0
