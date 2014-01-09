#!/bin/bash
#
# tomcat7      This shell script takes care of starting and stopping Tomcat
#
# chkconfig: 2345 95 10
#
### BEGIN INIT INFO
# Provides: tomcat7
# Required-Start: $network $syslog
# Required-Stop: $network $syslog
# Default-Start:
# Default-Stop:
# Description: Release implementation for Servlet 2.5 and JSP 2.1
# Short-Description: start and stop tomcat
### END INIT INFO

#
# Written by Khalid J Hosein, Platform28, Dec 2013
# with heavy inspiration from:
# - Tomcat6 init script shipped with Red Hat distros
# - https://gist.github.com/pdeschen/5564411/
# - http://wiki.unixsol.co.uk/index.php/Install_Tomcat_7,_Redis_2.6,_MySQL_on_CentOS
#

# Source init script functions:
. /etc/rc.d/init.d/functions

# Use the sysconfig file if it exists:
if [ -f /etc/sysconfig/tomcat7 ]; then
        . /etc/sysconfig/tomcat7
fi

NAME="$(basename $0)"
SU="/bin/su"
#TOMCAT_HOME="/home/logi/tomcat7"

# Define which connector port to use
#CONNECTOR_PORT="${CONNECTOR_PORT:-8080}"
 
# Path to the tomcat launch script
#TOMCAT_SCRIPT="${TOMCAT_HOME}/bin/catalina.sh"
 
# Tomcat program name
#TOMCAT_PROG="${NAME}"
 
# Define the tomcat username
#TOMCAT_USER="${TOMCAT_USER:-tomcat}"
 
# Define the tomcat log file
#TOMCAT_LOG="${TOMCAT_LOG:-${TOMCAT_HOME}/${NAME}-initd.log}"

# Location of PID file
#CATALINA_PID="/var/run/${NAME}.pid"

# how long to wait (in seconds) for shutdown to work:
SHUTDOWN_WAIT=15
SHUTDOWN_VERBOSE="true"

RETVAL="0"

function start() {
 
   echo -n "Starting ${TOMCAT_PROG}: "
   if [ "$RETVAL" != "0" ]; then
     echo_failure
     failure
     return
   fi
   if [ -f "/var/lock/subsys/${NAME}" ]; then
        if [ -f "${CATALINA_PID}" ]; then
            read kpid < ${CATALINA_PID}
#           if checkpid $kpid 2>&1; then
            if [ -d "/proc/${kpid}" ]; then
                success
                RETVAL="0"
                return
            fi
        fi
    fi
    # fix permissions on the log and pid files
    touch $CATALINA_PID 2>&1 || RETVAL="4"
    if [ "$RETVAL" -eq "0" -a "$?" -eq "0" ]; then
      chown ${TOMCAT_USER}:${TOMCAT_USER} $CATALINA_PID
    fi
    [ "$RETVAL" -eq "0" ] && touch $TOMCAT_LOG 2>&1 || RETVAL="4"
    if [ "$RETVAL" -eq "0" -a "$?" -eq "0" ]; then
      chown ${TOMCAT_USER}:${TOMCAT_USER} $TOMCAT_LOG
    fi
 
    [ "$RETVAL" -eq "0" ] &&  $SU - $TOMCAT_USER -c "${TOMCAT_SCRIPT} start" >> ${TOMCAT_LOG} 2>&1  || RETVAL="4"
    
    if [ "$RETVAL" -eq "0" ]; then
        echo_success
        success
        touch /var/lock/subsys/${NAME}
    else
        failure
    fi
}
 
function stop() {
    echo -n "Stopping ${TOMCAT_PROG}: "
    if [ -f "/var/lock/subsys/${NAME}" ]; then
      if [ "$RETVAL" -eq "0" ]; then
         touch /var/lock/subsys/${NAME} 2>&1 || RETVAL="4"
         [ "$RETVAL" -eq "0" ] && $SU - $TOMCAT_USER -c "${TOMCAT_SCRIPT} stop" >> ${TOMCAT_LOG} 2>&1 || RETVAL="4"
      fi
      if [ "$RETVAL" -eq "0" ]; then
         count="0"
         if [ -f "${CATALINA_PID}" ]; then
            read kpid < ${CATALINA_PID}
            until [ "$(ps --pid $kpid | grep -c $kpid)" -eq "0" ] || \
                      [ "$count" -gt "$SHUTDOWN_WAIT" ]; do
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        echo "waiting for processes $kpid to exit"
                    fi
                    sleep 1
                    let count="${count}+1"
                done
                if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        echo "killing processes which did not stop after ${SHUTDOWN_WAIT} seconds"
                        failure
                    fi
                    kill -9 $kpid
                fi
                success
            fi
            rm -f /var/lock/subsys/${NAME} ${CATALINA_PID}
        else
            failure
            RETVAL="4"
        fi
    else
        success
        RETVAL="0"
    fi
}
function forcestop {
    echo -n "Stopping ${TOMCAT_PROG}: "
    if [ -f "/var/lock/subsys/${NAME}" ]; then
      if [ "$RETVAL" -eq "0" ]; then
         touch /var/lock/subsys/${NAME} 2>&1 || RETVAL="4"
         [ "$RETVAL" -eq "0" ] && $SU - $TOMCAT_USER -c "${TOMCAT_SCRIPT} stop -force" >> ${TOMCAT_LOG} 2>&1 || RETVAL="4"
      fi
      if [ "$RETVAL" -eq "0" ]; then
         count="0"
         if [ -f "${CATALINA_PID}" ]; then
            read kpid < ${CATALINA_PID}
            until [ "$(ps --pid $kpid | grep -c $kpid)" -eq "0" ] || \
                      [ "$count" -gt "$SHUTDOWN_WAIT" ]; do
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        echo "waiting for processes $kpid to exit"
                    fi
                    sleep 1
                    let count="${count}+1"
                done
                if [ "$count" -gt "$SHUTDOWN_WAIT" ]; then
                    if [ "$SHUTDOWN_VERBOSE" = "true" ]; then
                        echo "killing processes which did not stop after ${SHUTDOWN_WAIT} seconds"
                        failure
                    fi
                    kill -9 $kpid
                fi
                success
            fi
            rm -f /var/lock/subsys/${NAME} ${CATALINA_PID}
        else
            failure
            RETVAL="4"
        fi
    else
        success
        RETVAL="0"
    fi
}
function status()
{
   checkpidfile
   if [ "$RETVAL" -eq "0" ]; then
      echo "${NAME} (pid ${kpid}) is running..."
      failure
   elif [ "$RETVAL" -eq "1" ]; then
      echo "PID file exists, but process is not running"
      failure
   else
      checklockfile
      if [ "$RETVAL" -eq "2" ]; then
         echo "${NAME} lockfile exists but process is not running"
         failure
      else
         pid="$(/usr/bin/pgrep -d , -u ${TOMCAT_USER} -G ${TOMCAT_USER} java)"
         if [ -z "$pid" ]; then
             success
             echo "${NAME} is stopped"
             RETVAL="3"
         else
             success
             echo "${NAME} (pid $pid) is running..."
             RETVAL="0"
         fi
      fi
  fi
}
 
function checklockfile()
{
   if [ -f /var/lock/subsys/${NAME} ]; then
      pid="$(/usr/bin/pgrep -d , -u ${TOMCAT_USER} -G ${TOMCAT_USER} java)"
      # The lockfile exists but the process is not running
      if [ -z "$pid" ]; then
         RETVAL="2"
      fi
   fi
}
function checkpidfile()
{
   if [ -f "${CATALINA_PID}" ]; then
      read kpid < ${CATALINA_PID}
      if [ -d "/proc/${kpid}" ]; then
        # The pid file exists and the process is running
          RETVAL="0"
      else
        # The pid file exists but the process is not running
         RETVAL="1"
         return
      fi
   fi
   # pid file does not exist and program is not running
   RETVAL="3"
}

function usage()
{
   echo "Usage: $0 {start|stop|restart|condrestart|try-restart|forcestop|status}"
   echo "       Try $0 'stopforce' before using kill/kill -9"
   echo "       bin/catalina.sh accepts additional parameters."
   RETVAL="2"
}

# See how we were called:
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    condrestart|try-restart)
        if [ -f "${CATALINA_PID}" ]; then
            stop
            start
        fi
        ;;
    forcestop)
        if [ -f "${CATALINA_PID}" ]; then
            forcestop
        fi
        ;;
    status)
        status
        ;;
    *)
      usage
      ;;
esac
 
exit $RETVAL
