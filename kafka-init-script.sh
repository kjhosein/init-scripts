#!/bin/sh
#
# chkconfig: 345 99 01
# description: Kafka
#
# File : Kafka
#
# Description: Starts and stops the Kafka server
#

source /etc/rc.d/init.d/functions

KAFKA_HOME=/opt/kafka
KAFKA_USER=kafka
# See how we were called.
case "$1" in

  start)
    echo -n "Starting Kafka:"
    /sbin/runuser $KAFKA_USER -c "nohup $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > /var/log/kafka/server.out 2> /var/log/kafka/server.err &"
    sleep 2
    k_pid=`ps -ef | grep 'java.*kafka.Kafka'| grep -v grep | awk '{print $2}'`
    if [ "$k_pid" = "" ] ; then
        echo "Failed to start Kafka"
        exit 3
    else
        echo "Successfully started Kafka - PID: $k_pid"
        exit 0
    fi
    ;;

  stop)
    echo -n "Stopping Kafka: "
    /sbin/runuser  $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk '{print \$2}' | xargs kill"
    echo " done."
    exit 0
    ;;

  hardstop)
    echo -n "Stopping (hard) Kafka: "
    /sbin/runuser  $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk '{print \$2}' | xargs kill -9"
    echo " done."
    exit 0
    ;;

  status)
    c_pid=`ps -ef | grep kafka.Kafka | grep -v grep | awk '{print $2}'`
    if [ "$c_pid" = "" ] ; then
      echo "Stopped. Try restarting with service $0 start."
      exit 3
    else
      echo "Running with PID $c_pid"
      exit 0
    fi
    ;;

  restart)
    stop
    start
    ;;

  *)
    echo "Usage: cassandra {start|stop|hardstop|status|restart}"
    exit 1
    ;;

esac
