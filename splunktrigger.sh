#!/bin/bash
#
# splunksearch: This script would scan splunk for messages and email when alerts are found
#
CONFIGFILE=splunkappconfig.properties
SPLUNK=/opt/splunk/bin/splunk
CONFIGARRAY=()
RESULTARRAY=()

function splunksearch()
{
   IFS=$'\r\n' RESULTARRAY=(`${SPLUNK} search $1 -earliest=-5m`)
   return 0 
}

function parsesplunkconfig()
{
   if [[ ! -r ${CONFIGFILE} ]] 
     then 
     echo "parsesplunkconfig() cannot read configuration file"
     exit 2
   fi
   IFS=$'\r\n' CONFIGARRAY=(`cat ${CONFIGFILE}`)  
   return 0
}

# parsing the configuration file
parsesplunkconfig

# goign throug the search strings in configuration file
for i in ${CONFIGARRAY[*]}
do 

  CURRENTSEARCHSTRING=`echo $i  | awk -F"|" '{print $1}'`
  SEVERITY=`echo $i  | awk -F"|" '{print $2}'`
  MAILINGLIST=`echo $i  | awk -F"|" '{print $3}'`
  splunksearch ${CURRENTSEARCHSTRING}
  if [ ! -z "${CURRENTSEARCHSTRING}" ]                           # Is parameter #1 zero length?
  then
     splunksearch ${CURRENTSEARCHSTRING}
  fi

  # if search returned values send alert
  if [[ ${#RESULTARRAY[*]} != 0 ]] 
  then
     echo ${RESULTARRAY[*]} |  mail -s ${SEVERITY} ${MAILINGLIST}
  fi

done

# return something good .. we finished.
exit 0
