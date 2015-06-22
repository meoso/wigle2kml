changelog 2015-06-22: changed csv handling; please install csvtool and remove ./NEW_ZIP.csv

---

:octocat: ./wigle2kml.sh - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe

Usage: `./wigle2kml.sh username zipcode variance lastseen ["[-v] filter[|filter[|filter]...]"]`

Outputs: zip.txt and zip.kml files

Dependencies: `csvtool`, `curl`, `bc`, `grep`, `egrep`, `awk`, WiGLE.net account.

Automatically downloads http://www.unitedstateszipcodes.org/zip_code_database.csv.  I chose this database because my zipcode had an accurate lat/long as opposed to other databases found.

Using api reference: http://www5.musatcha.com/musatcha/computers/wigleapi.htm ; however, not using the `pagestart` variable as it seems not to be limited to 1000 records as stated, but rather seems to be an undocumented 11k records.  Also, this API is slightly stale and thus the wigle.net output is now 18 columns.

Parameters:
zipcode: required ; 5-digit U.S. postal-code only ; uses this to parse data from zip_code_database.csv
variance: required ; small decimal number (0.01 to 0.2); example 0.03
lastseen: required ; in the form of YYYYMMDDHHMMSS; example 20140101000000
filter: optional ; however, quotes ("") are required around filter list; passed verbatim to egrep, so `-v` is inverse

example usage: `./wigle2kml.sh irongeek 47150 0.03 20140101000000 "linksys"`
example usage: `./wigle2kml.sh irongeek 47150 0.03 20140101000000 "-v MIFI|HP-Print|2WIRE"`


---


:octocat: filter-existing.sh - Filter existing zip.txt file locally.

Usage: `./filter-existing.sh zip ["[-v] filter[|filter[|filter]]"]`

Outputs: zip_filtered.txt and zip_filtered.kml files

Dependencies: `egrep`

Parameters:
zip - required ; 5-digit U.S. postal-code only ; reads local zip.txt file
filter - optional ; however, quotes ("") are required around filter list; passed verbatim to egrep, so -v is inverse

example usage: `./filter-existing.sh 47150 "linksys"`
example usage: `./filter-existing.sh 47150 "-v MIFI|HP-Print|2WIRE"`
