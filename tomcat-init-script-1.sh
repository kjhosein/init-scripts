#!/bin/sh
#
# Startup script for Tomcat 6, the Apache Servlet Engine
#
# chkconfig: 2345 80 20
# description: Tomcat 6.0.13 is the Apache Servlet Engine 
# processname: tomcat
# pidfile: /var/run/tomcat5.pid
# config:  /usr/share/tomcat/conf/tomcat6.conf
#

# Source function library.
if [ -x /etc/rc.d/init.d/functions ]; then
. /etc/rc.d/init.d/functions
fi

# For SELinux we need to use 'runuser' not 'su'
if [ -x /sbin/runuser ]
then
        SU=runuser
else
        SU=su
fi

# Get Tomcat config

TOMCAT_CFG="/usr/share/tomcat/conf/tomcat6.conf"

[ -r "$TOMCAT_CFG" ] && . "${TOMCAT_CFG}"

# Path to the tomcat launch script (direct don't use wrapper)
TOMCAT_SCRIPT=/usr/share/tomcat/bin/catalina.sh

# Tomcat name :)
TOMCAT_PROG=tomcat6

# if TOMCAT_USER is not set, use tomcat5 like Apache HTTP server
if [ -z "$TOMCAT_USER" ]; then
    TOMCAT_USER="tomcat"
fi

RETVAL=0

# See how we were called.
start() {
    printf "Starting %s: " "$TOMCAT_PROG"

        if [ -f /var/lock/subsys/tomcat6 ] ; then
                if [ -f /var/run/tomcat5.pid ]; then
                        read kpid < /var/run/tomcat5.pid
                        if checkpid $kpid 2>&1; then
                                printf "process allready running\n"
                                return -1
                        else
                                printf "lock file found but no process running for pid %s, continuing\n" "$kpid"
                        fi
                fi
        fi

        export CATALINA_PID=/var/run/tomcat6.pid
        touch $CATALINA_PID
        chown $TOMCAT_USER:$TOMCAT_USER $CATALINA_PID

#        $TOMCAT_RELINK_SCRIPT

        if [ -x /etc/rc.d/init.d/functions ]; then
                daemon --user $TOMCAT_USER $TOMCAT_SCRIPT start
        else
                $SU - $TOMCAT_USER -c "$TOMCAT_SCRIPT start"
        fi

        RETVAL=$?
        echo
        [ $RETVAL = 0 ] && touch /var/lock/subsys/tomcat6
        return $RETVAL
}

stop() {
    printf "Stopping %s: " "$TOMCAT_PROG"

    if [ -f /var/lock/subsys/tomcat6 ] ; then
      if [ -x /etc/rc.d/init.d/functions ]; then
          daemon --user $TOMCAT_USER $TOMCAT_SCRIPT stop
      else
          $SU - $TOMCAT_USER -c "$TOMCAT_SCRIPT stop"
      fi
      RETVAL=$?

      if [ $RETVAL = 0 ]; then
        count=0;

        if [ -f /var/run/tomcat6.pid ]; then

            read kpid < /var/run/tomcat6.pid
            let kwait=$SHUTDOWN_WAIT

            until [ `ps --pid $kpid | grep -c $kpid` = '0' ] || [ $count -gt $kwait ]
            do
                printf "\nwaiting for processes to exit";
                sleep 1
                let count=$count+1;
            done

            if [ $count -gt $kwait ]; then
                printf "\nkilling processes which didn't stop after %s seconds" "$SHUTDOWN_WAIT"
                kill -9 $kpid
            fi

            if [ $count -gt 0 ]; then
                printf "\n"
            fi
        fi

                rm -f /var/lock/subsys/tomcat5 /var/run/tomcat5.pid
    fi

    fi
}


# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 2
        start
        ;;
  condrestart)
        if [ -f /var/run/tomcat6.pid ] ; then
                stop
                start
        fi
        ;;
  *)
        printf "Usage: %s {start|stop|restart|condrestart}\n" "$TOMCAT_PROG"
        exit 1
esac

exit $RETVAL