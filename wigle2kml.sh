#!/bin/bash

#Check for at least 4 arguments
if [ $# -lt 4 ] ; then
	echo
	echo "$0 - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe"
	echo
	echo "Usage: $0 username zipcode variance lastseen [\"[-v] filter[|filter[|filter]]\"]"
	echo
	echo "Outputs: zip.txt and zip.kml files"
	echo
	echo "Dependencies: csvtool, curl, bc, grep, egrep, awk, WiGLE.net account"
	echo "Automatically downloads http://www.unitedstateszipcodes.org/zip_code_database.csv"
	echo "Automatically downloads http://standards-oui.ieee.org/oui.txt"
	echo "Using API reference: http://www5.musatcha.com/musatcha/computers/wigleapi.htm"
	echo
	echo "Parameters"
	echo "zipcode: required ; 5-digit U.S. postal-code only ; uses this to parse data from zip_code_database.csv"
	echo "variance: required ; small decimal number (0.01 to 0.2); example 0.03"
	echo "lastseen: required ; in the form of YYYY[MMDD[HHMMSS]]; example 2015 or 20150701 or 20141231235959"
	echo "filter: optional ; however, quotes (\"\") should be used around filter list as it is passed verbatim to egrep. (-v is inverse)"
	echo
	echo "example usage: $0 irongeek 47150 0.03 20150101 \"[Ll]inksys\""
	echo "example usage: $0 irongeek 47150 0.03 20141231235959 \"-v MIFI|HP-Print|2WIRE\""
	echo
	exit 1
fi

if ! ( which csvtool 2>&1 >/dev/null )
then
	echo "Please install \"csvtool\" from your distribution repository. Aborted."
	echo ""
	exit 1
fi

username=$1
zip=$2
var=$3

case ${#4} in
4)
  lastupdt=$4"0101000000"
  ;;
8)
  lastupdt=$4"000000"
  ;;
14)
  lastupdt=$4
  ;;
*)
  echo "Invalid lastseen value."
  exit 1
  ;;
esac

if [[ -z $5 ]]
then
	filter=""
else
	filter=$5
fi

touch -d "$(date -d '30 days ago')" 30DAYSAGO

if ! [ -f zip_code_database.csv ] || [ zip_code_database.csv -ot 30DAYSAGO ]
then
	echo "Downloading Zip-Code database."
	curl -# --compressed -O http://www.unitedstateszipcodes.org/zip_code_database.csv
fi

if ! [ -f oui.txt ] || [ oui.txt -ot 30DAYSAGO ]
then
	echo "Downloading IEEE MA-L (MAC Vendors)."
	curl -# --compressed -O http://standards-oui.ieee.org/oui.txt
	cat oui.txt | grep -F "(base 16)" | awk '{$2=$3="" ; print $0}' | awk -F"   " '{print $1 ":" $2}' > tempOUI
	mv tempOUI oui.txt
fi

rm 30DAYSAGO 2>&1 >/dev/null

line=""
line=$(grep -m 1 ^"$zip" zip_code_database.csv)

if [ "${line}" == "" ]
then
	echo Zip "$zip" not found.
	exit 1
fi

#use csvtool for csv processing
IFS=' '
set -- $(grep -m 1 ^"$zip" zip_code_database.csv | csvtool col 10,11 - | awk -F, '{print $1 " " $2}')
lat=$1 long=$2

latrange1=$(echo "$lat-$var" | bc)
latrange2=$(echo "$lat+$var" | bc)
longrange1=$(echo "$long-$var" | bc)
longrange2=$(echo "$long+$var" | bc)

echo
echo "$0 processing for:"
echo "Zip: $zip"
echo "Lat: $lat"
echo "Long: $long"
echo "Variance: $var"
echo "Calculated range: ($latrange1,$longrange1) to ($latrange2,$longrange2)"
echo "Lastseen: $lastupdt"
if [ $filter ]
then
	echo "Filter: $filter"
else
	echo "No filter."
fi

function populateKMLfolder () {
	enc=$1
	folder=$2
	echo "Processing Enc=$enc ($folder)"

 	case $enc in
		"N")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/open.png"
			label_color="ff0000FF" #red #alpha/B/G/R
			;;
		"Y")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wep.png"
			label_color="ff00FFFF" #yellow #alpha/B/G/R
			;;
		"W")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wpa.png"
			label_color="ffFFFF00" #cyan #alpha/B/G/R
			;;
		"2")
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/wpa2.png"
			label_color="ffFF6600" #blue #alpha/B/G/R
			;;
		*)
			iconwep="https://dl.dropboxusercontent.com/u/7346386/wifi/unknown.png"
			label_color="ffFF0099" #purple #alpha/B/G/R
	esac

	echo "<Folder><name>$folder</name><open>0</open>" >> "$zip".kml

	#as of Nov 2014: 18 elements (0-17)
	#  0     1     2     3     4     5      6       7         8       9   10   11      12      13       14       15       16     17
	#netid~ssid~comment~name~type~freenet~paynet~firsttime~lasttime~flags~wep~trilat~trilong~lastupdt~channel~bcninterval~qos~userfound
	fileline=0 #debug
	while read line ; do
		fileline=$((fileline+1)) #debug
		IFS='~' read -a array <<< "$line"
		array[0]=${array[0]^^} #to upper case
		#echo "file-line $fileline: ${array[0]} ${array[1]} ${array[10]}" #debug

		#find MAC vendor
		lookup=$(echo ${array[0]} | awk -F":" '{print $1 $2 $3}')
		vendor=$(grep -m 1 ^"$lookup" oui.txt | awk -F':' '{print $2}')

		if [[ "${#array[@]}" -eq "18" ]] && [[ "${array[10]}" == "$enc" ]]  #needed == instead of -eq due: syntax error: operand expected (error token is "?")
		then
			echo "<Placemark>" >> "$zip".kml
			echo "	<description>" >> "$zip".kml
			echo "		<![CDATA[" >> "$zip".kml
			echo "			SSID: ${array[1]} <BR>" >> "$zip".kml
			echo "			MAC: ${array[0]} <BR>" >> "$zip".kml
			if [ "${array[2]}" != " " ] ; then echo "			Comment: ${array[2]} <BR>" >> "$zip".kml ; fi
			if [ "${array[3]}" != " " ] ; then echo "			Name: ${array[3]} <BR>" >> "$zip".kml ; fi
			echo "			Vendor: ${vendor} <BR>" >> "$zip".kml
			echo "			Type: ${array[4]} <BR>" >> "$zip".kml
			if [ "${array[5]}" != "?" ] ; then echo "			Freenet: Y <BR>" >> "$zip".kml ; fi
			if [ "${array[6]}" != "?" ] ; then echo "			Paynet: Y <BR>" >> "$zip".kml ; fi
			echo "			Encryption: ${array[10]} <BR>" >> "$zip".kml
			echo "			Channel: ${array[14]} <BR>" >> "$zip".kml
			echo "			QOS: ${array[16]} <BR>" >> "$zip".kml
			if [ "${array[9]}" != " " ] ; then echo "			Flags: ${array[9]} <BR>" >> "$zip".kml ; fi
			echo "			First Seen: $(echo ${array[7]} | sed s/[:-]//g ) <BR>" >> "$zip".kml
			if [ "${array[8]}" != " " ] ; then echo "			Last Seen: ${array[8]} <BR>" >> "$zip".kml ; fi
			echo "			Last Update: ${array[13]:0:8} ${array[13]:8:6} <BR>" >> "$zip".kml
			echo "			Latitude: ${array[11]} <BR>" >> "$zip".kml
			echo "			Longitude: ${array[12]} <BR>" >> "$zip".kml
			if [ "${array[15]}" != " " ] ; then echo "			Beacon Interval: ${array[15]}ms <BR>" >> "$zip".kml ; fi
			echo "			Userfound: ${array[17]} <BR>" >> "$zip".kml
			echo "		]]>" >> "$zip".kml
			echo "	</description>" >> "$zip".kml
			echo "	<name><![CDATA[${array[1]}]]></name>" >> "$zip".kml
			echo "	<Style>" >> "$zip".kml
			echo "		<IconStyle>" >> "$zip".kml
			echo "			<scale>1.0</scale>" >> "$zip".kml
			echo "			<Icon>;" >> "$zip".kml
			echo "				<href>$iconwep</href>" >> "$zip".kml
			echo "			</Icon>" >> "$zip".kml
			echo "		</IconStyle>" >> "$zip".kml
			echo "		<LabelStyle>" >> "$zip".kml
			echo "			<scale>0.70</scale>" >> "$zip".kml
			echo "			<color>${label_color}</color>" >> "$zip".kml
			echo "		</LabelStyle>" >> "$zip".kml
			echo "	</Style>" >> "$zip".kml
			echo "	<Point id=\"$folder_${array[0]}\">" >> "$zip".kml
			echo "		<coordinates>${array[12]},${array[11]}</coordinates>" >> "$zip".kml
			echo "	</Point>" >> "$zip".kml
			echo "</Placemark>" >> "$zip".kml
		fi
	done <"$zip".txt

	echo "</Folder>" >> "$zip".kml
} ##END function

echo
read -s -p "Password for WiGLE.net user $username:" password
echo ""

#successful login will result in 302
result=$(curl -s -c cookie.txt -d "credential_0=$username&credential_1=$password&noexpire=off" https://wigle.net/gps/gps/GPSDB/login/ | grep 302)

# if no error (if successful 302)
if [[ $? == 0 ]]
then
	echo "Downloading WiGLE data:"
	#curl -b cookie.txt -o "$zip".txt "https://wigle.net/gpsopen/gps/GPSDB/confirmquery?longrange1=$longrange1&longrange2=$longrange2&latrange1=$latrange1&latrange2=$latrange2&simple=true&lastupdt=$lastupdt"
	#URL changed:
	curl -b cookie.txt -o "$zip".txt "https://wigle.net/gps/gps/main/confirmquery?longrange1=$longrange1&longrange2=$longrange2&latrange1=$latrange1&latrange2=$latrange2&simple=true&lastupdt=$lastupdt"

	# apply filter if one was provided (ignorant of fields -- whole-line filtering)
	if ! [[ -z $filter ]]
	then
		egrep $filter "$zip".txt > filter.txt
		mv filter.txt "$zip".txt
	fi

	#cat "$zip".txt #debug
	echo

	#open new kml
	echo '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://earth.google.com/kml/2.0"><Folder><name>'${zip}' WiGLE Data</name><open>1</open>' > "$zip".kml

	populateKMLfolder "N" "Open"
	populateKMLfolder "Y" "WEP"
	populateKMLfolder "W" "WPA"
	populateKMLfolder "2" "WPA2"
	populateKMLfolder "?" "Unknown"

	#close kml
	echo '</Folder></kml>' >> "$zip".kml
	echo "Finished: files created: $zip.txt and $zip.kml"
	echo
else
	echo "failed to authenticate."
	exit 1
fi

exit 0
