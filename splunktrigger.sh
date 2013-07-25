#!/bin/bash
#
# splunksearch: This script would scan splunk for messages and email when alerts are found
#
#
#

CONFIGFILE=splunkappconfig.properties
SPLUNK=/opt/splunk/bin


function status()
{
   checkpidfile 
   if [ "$RETVAL" -eq "0" ]; then
      log_success_msg "${NAME} (pid ${kpid}) is running..."
   elif [ "$RETVAL" -eq "1" ]; then
      log_failure_msg "PID file exists, but process is not running"
   else 
      checklockfile
      if [ "$RETVAL" -eq "2" ]; then
         log_failure_msg "${NAME} lockfile exists but process is not running"
      else
         pid="$(/usr/bin/pgrep -u ${TOMCAT_USER} -f ${NAME})"
         if [ -z "$pid" ]; then
             log_success_msg "${NAME} is stopped"
             RETVAL="3"
         else
             log_success_msg "${NAME} (pid $pid) is running..."
             RETVAL="0"
         fi
      fi
  fi
}

function parsesplunkconfig()
{
   echo "Usage: $0 {start|stop|restart|condrestart|try-restart|reload|force-reload|status|version}"
   RETVAL="2"
}

function usage()
{
   echo "Usage: $0 {start|stop|restart|condrestart|try-restart|reload|force-reload|status|version}"
   RETVAL="2"
}

# See how we were called.
RETVAL="0"
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    version)
	 	version
#        ${TOMCAT_SCRIPT} version
        ;;
    *)
      usage
      ;;
esac

exit $RETVAL
