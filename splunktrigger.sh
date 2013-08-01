#!/bin/bash
#
# splunksearch: This script would scan splunk for messages and email when alerts are found
#
HOMEDIR=/opt/splunkmonitor
CONFIGFILE=${HOMEDIR}/splunkappconfig.properties
SPLUNK=/opt/splunk/bin/splunk
CONFIGARRAY=()
ALERTCONFIGLIST=()
RESULTARRAY=()

function createJSONpayload()
{
#Example JSON Template
#{"Application":"NMA", "Class":"NMA", "Epage":"GROUP_NMA", "Message_Catalog":"865", "ServiceNow":"true", "ServiceNow_AssignmentGroup":"NMASupport", "Severity":"C", "TEC_Group":"9849", "Trigger":{ "AWS_Account":"994390710894", "AWS_Region":"us-east-1", "Instance":"???", "Query":"source=/var/log/tomcat6/catalina.out SYSTEM_ERROR", "Result":"LOTOFTEXT.... ", "Timestamp":"time the script ran" }}
rm ${HOMEDIR}/jsonpayload.file
#Creating the json file to send to the splunk end point
cat > ${HOMEDIR}/jsonpayload.file <<EOF
{"Application":"${ALERTCONFIGLIST[0]}", "Class":"${ALERTCONFIGLIST[1]}", "Epage":"${ALERTCONFIGLIST[2]}", "Message_Catalog":"${ALERTCONFIGLIST[3]}", "ServiceNow":"${ALERTCONFIGLIST[4]}", "ServiceNow_AssignmentGroup":"${ALERTCONFIGLIST[5]}", "Severity":"${SEVERITY}", "TEC_Group":"${ALERTCONFIGLIST[6]}", "Trigger":{ "AWS_Account":"${ALERTCONFIGLIST[7]}", "AWS_Region":"${ALERTCONFIGLIST[8]}", "Instance":"${INSTANCE}", "Query":"${CURRENTSEARCHSTRING}", "Result":"${RESULTARRAY[*]}", "Timestamp":"${CURRENTDATETIME}" }}
EOF

}

function splunksearch()
{
   IFS=$'\r\n' RESULTARRAY=(`${SPLUNK} search "$1 earliest=-5m"`)
   return 0 
}

function parsesplunkconfig()
{
   if [[ ! -r ${CONFIGFILE} ]] 
     then 
     echo "parsesplunkconfig() cannot read configuration file"
     exit 2
   fi

   # populating the configuration list from the first line if the configuraiton file
   ALERTCONFIGLIST=(`head -1 ${CONFIGFILE} | grep "^#" | sed -E 's/[|]/ /g' | sed -E 's/[#]//g'`)
   
   if [[ ${#ALERTCONFIGLIST[*]} == 0 ]]
   then
     echo "No Alert header found in the configuration file"
     echo "please provide header like so .. "
     echo "#<application>|<class>|<epage>|<message catalog>|<service now>|<servicenow assignment group>|<tec group>|<aws account>|<aws region>"
     echo "For Ex: #NMA|NMA|GROUP_NMA|865|true|NMASupport|9849|994390710894|us-east-1"
     exit 2
   fi

   # reading the rest of the configuration file
   IFS=$'\r\n' CONFIGARRAY=(`cat ${CONFIGFILE} | grep -v "^#"`)  
   return 0
}

# parsing the configuration file
parsesplunkconfig

CURRENTDATETIME=`date`

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
     createJSONpayload
     #echo ${RESULTARRAY[*]} |  mail -s ${SEVERITY} ${MAILINGLIST}
     echo "curl -F payload=@${HOMEDIR}/jsonpayload.file -X POST -H 'Content-type:application/json' -v http://localhost:5000/mycontroller/myaction"
  fi

done

# return something good .. we finished.
exit 0
