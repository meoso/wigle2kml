changelog 2015-06-22: changed csv handling; please install csvtool and remove ./NEW_ZIP.csv

changleog 2015-06-25: added MAC Vendor lookup; this significantly increases processing time - If you do not want this feature stay at commit d873cd0

---

:octocat: ./wigle2kml.sh - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe

Usage: `./wigle2kml.sh username zipcode variance lastseen ["[-v] filter[|filter[|filter]...]"]`

Outputs: zip.txt and zip.kml files

Dependencies: `csvtool`, `curl`, `bc`, `grep`, `egrep`, `awk`, WiGLE.net account.

Automatically downloads http://www.unitedstateszipcodes.org/zip_code_database.csv if nonexistent or older than 30 days.  I chose this database because my zipcode had an accurate lat/long as opposed to other databases found.

Automatically downloads http://standards-oui.ieee.org/oui.txt if nonexistent or older than 30 days.  Using IEEE MA-L MAC address oui.txt for vendor lookup.

Using api reference: http://www5.musatcha.com/musatcha/computers/wigleapi.htm ; however, not using the `pagestart` variable as it seems not to be limited to 1000 records as stated, but rather seems to be an undocumented 11k records.  Also, this API is slightly stale and thus the wigle.net output is now 18 columns.

Parameters:

zipcode: required ; 5-digit U.S. postal-code only ; uses this to parse data from zip_code_database.csv

variance: required ; small decimal number (0.01 to 0.2); example 0.03

lastseen: required ; in the form of YYYY[MMDD[HHMMSS]]; example 2015 or 20150701 or 20141231235959

filter: optional ; however, quotes ("") should be used around filter list as it is passed verbatim to egrep (`-v` is inverse)

example usage: `./wigle2kml.sh irongeek 47150 0.03 2015 "[Ll]inksys"`

example usage: `./wigle2kml.sh irongeek 47150 0.03 20140731000000 "-v MIFI|HP-Print|2WIRE"`


---


:octocat: filter-existing.sh - Filter existing zip.txt file locally. -- OUT OF DATE as compared to ./wigle2kml.sh -- I'm considering adding `getopts` to ./wigle2kml.sh to avoid this file altogether.

Usage: `./filter-existing.sh zip ["[-v] filter[|filter[|filter]]"]`

Outputs: zip_filtered.txt and zip_filtered.kml files

Dependencies: `egrep`

Parameters:
zip - required ; 5-digit U.S. postal-code only ; reads local zip.txt file
filter - optional ; however, quotes ("") should be used around filter list as it is passed verbatim to egrep (`-v` is inverse)

example usage: `./filter-existing.sh 47150 "[Ll]inksys"`

example usage: `./filter-existing.sh 47150 "-v MIFI|HP-Print|2WIRE"`
