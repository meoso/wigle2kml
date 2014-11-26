./wigle2kml.sh - The WiGLE.net to KML converter in BASH - by NJD - Inspired by irongeek.com's igigle.exe

Usage: `./wigle2kml.sh username zipcode variance lastseen ["[-v] filter[|filter[|filter]...]"]`

Dependencies: `curl`, `bc`, `grep`, `egrep`, `awk`

Automatically downloads http://www.unitedstateszipcodes.org/zip_code_database.csv

Using api reference: http://www5.musatcha.com/musatcha/computers/wigleapi.htm

zipcode: 5-digit postal-code only

variance: small decimal number (0.01 to 0.2); example 0.02

lastseen: in the form of YYYYMMDDHHMMSS; example 20140101000000

filter: optional parameter; however, quotes ("") are required around filter list; passed verbatim to egrep, so `-v` is inverse

example: `./wigle2kml.sh irongeek 47150 0.02 20140101000000 "linksys"`

example: `./wigle2kml.sh irongeek 47150 0.02 20140101000000 "-v MIFI|HP-Print|2WIRE"`
