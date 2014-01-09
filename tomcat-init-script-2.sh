#!/bin/sh
#
# Start script for Jakarta Tomcat 5/6/7
#
# chkconfig: 2345 84 15
# description: Jakarta Tomcat 6 start script – visit manpage.ch for updates
# processname: tomcat
# pidfile: /var/run/tomcat.pid

. /etc/rc.d/init.d/functions

TOMCAT_USER=<tomcat_username>
TOMCAT_PROCESS=<tomcat_username>
PS_HEADER=`ps www -u ${TOMCAT_USER} | grep PID`

RETVAL=0

running() {
        ps www -u ${TOMCAT_USER} | grep org.apache.catalina.startup.Bootstrap | grep -v gr                                                                                                                      ep
}

case “$1″ in
   start)
        if [ -f /var/lock/subsys/${TOMCAT_PROCESS} ] ; then
            echo “${TOMCAT_PROCESS} already running”
            exit 1
        fi
        echo “Starting ${TOMCAT_PROCESS}:”
        echo
        su – ${TOMCAT_USER} -c “~${TOMCAT_USER}/bin/catalina.sh start”
        RETVAL=$?
        [ ${RETVAL} = 0 ] && touch /var/lock/subsys/${TOMCAT_PROCESS}
        ;;
   stop)
        if [ ! -f /var/lock/subsys/${TOMCAT_PROCESS} ] ; then
            echo “${TOMCAT_PROCESS} not running”
            exit 1
        fi
        echo “Shutting down ${TOMCAT_PROCESS}:”
        echo
        su – ${TOMCAT_USER} -c “~${TOMCAT_USER}/bin/catalina.sh stop”
        RETVAL=$?
        [ ${RETVAL} = 0 ] && rm -f /var/lock/subsys/${TOMCAT_PROCESS}
        ;;
   stopforce)
        echo “Enforcedly shutting down ${TOMCAT_PROCESS}: “
        echo
        su – ${TOMCAT_USER} -c “~${TOMCAT_USER}/bin/catalina.sh stop -force”
        port | grep 8080 | awk ‘{ print $7}’ | awk -F/ ‘{ print $1 }’
        RETVAL=$?
        [ ${RETVAL} = 0 ] && rm -f /var/lock/subsys/${TOMCAT_PROCESS}
        ;;
   restart)
        $0 stop
        sleep 5
        $0 start
        ;;
   kill)
        echo “Killing ${TOMCAT_PROCESS} process: “
        PID=`running | gawk ‘{print $1}’`
        kill -9 $PID
        if [ -f /var/lock/subsys/${TOMCAT_PROCESS} ] ; then
            rm -f /var/lock/subsys/${TOMCAT_PROCESS}
        fi
        ;;
   status)
        if [ -f /var/lock/subsys/${TOMCAT_PROCESS} ] ; then
            echo “Process ${TOMCAT_PROCESS} running with properties:”
            echo
            ps www -u ${TOMCAT_USER}
        else
            echo “Process ${TOMCAT_PROCESS} not running”
        fi
        ;;
   pid)
        if [ -f /var/lock/subsys/${TOMCAT_PROCESS} ] ; then
            echo -n “Process ${TOMCAT_PROCESS} running with number “
            running | gawk ‘{print $1}’
        else
            echo “Process ${TOMCAT_PROCESS} not running”
        fi
        ;;
   version)
        echo “Checking version for ${TOMCAT_PROCESS}:”
        echo
        su – ${TOMCAT_USER} -c “~${TOMCAT_USER}/bin/catalina.sh version”
        ;;
   *)
        echo “Usage: $0 {start|stop|stopforce|kill|restart|status|pid|version}”
        echo “       If you need to supply ‘kill’ try ‘stopforce’ first”
        echo “Command ~${TOMCAT_USER}/bin/catalina.sh accepts additional parameters as wel                                                                                                                      l”
        exit 1
esac
exit ${RETVAL}