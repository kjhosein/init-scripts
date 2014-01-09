#!/bin/sh
#
# zookeeper ZooKeeper Server
#
# chkconfig: 345 88 05
# description: Enable ZooKeeper Server
#

### BEGIN INIT INFO
# Provides:          zookeeper
# Default-Start:
# Default-Stop:
# Required-Start:    $remote_fs $network
# Required-Stop:     $remote_fs $network
# Description:       zookeeper Server
# Short-Description: Enable zookeeper  Server
### END INIT INFO

# forked from: https://github.com/globocom/zookeeper-centos-6/blob/master/redhat/zookeeper.init
# Modfied by Khalid J Hosein, Platform28
# Dec 2013

# Source function library.
. /etc/rc.d/init.d/functions

prog="zookeeper"
desc="zookeeper Server"

[ -e /etc/sysconfig/$prog ] && . /etc/sysconfig/$prog

lockfile="/var/lock/subsys/$prog"
pidfile="/var/run/$prog.pid"

[ "x$JMXLOCALONLY" = "x" ] && JMXLOCALONLY=false

if [ "x$JMXDISABLE" = "x" ]
then
    # for some reason these two options are necessary on jdk6 on Ubuntu
    #   accord to the docs they are not necessary, but otw jconsole cannot
    #   do a local attach
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=$JMXLOCALONLY org.apache.zookeeper.server.quorum.QuorumPeerMain"
else
    ZOOMAIN="org.apache.zookeeper.server.quorum.QuorumPeerMain"
fi

ZOOBINDIR="/opt/zookeeper/bin"
ZOOCFGDIR="/etc/zookeeper"
ZOOCFG="zoo.cfg"
ZOOCFG="$ZOOCFGDIR/$ZOOCFG"
ZOO_LOG_DIR="/var/log/zookeeper"

[ -e "$ZOOCFGDIR/java.env" ] && . "$ZOOCFGDIR/java.env"

[ "x$ZOO_LOG4J_PROP" = "x" ] && ZOO_LOG4J_PROP="INFO,CONSOLE"

for f in ${ZOOBINDIR}/../zookeeper-*.jar
do 
    CLASSPATH="$CLASSPATH:$f"
done

ZOOLIBDIR=${ZOOLIBDIR:-$ZOOBINDIR/../lib}
for i in "$ZOOLIBDIR"/*.jar
do
    CLASSPATH="$CLASSPATH:$i"
done

#add the zoocfg dir to classpath
CLASSPATH=$ZOOCFGDIR:$CLASSPATH

cmd="java  \"-Dzookeeper.log.dir=${ZOO_LOG_DIR}\" \"-Dzookeeper.root.logger=${ZOO_LOG4J_PROP}\" -cp ${CLASSPATH} ${JVMFLAGS} ${ZOOMAIN} ${ZOOCFG} & echo \$! > ${pidfile}"


start() {
    echo -n $"Starting $desc ($prog): "
    touch $pidfile && chown zookeeper $pidfile
    daemon --user zookeeper --pidfile $pidfile "$cmd"
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc -p $pidfile  $prog
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    stop
    start
}

reload() {
    restart
}

get_status() {
    status $prog
    RETVAL=$?
    STAT=`echo stat | nc localhost $(grep clientPort $ZOOCFG | sed -e 's/.*=//') 2> /dev/null| grep Mode`
    if [ "x$STAT" = "x" ]
    then
        echo "Error contacting service."
    else
        echo $STAT
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    reload)
        reload
        ;;
    condrestart)
        [ -e /var/lock/subsys/$prog ] && restart
        RETVAL=$?
        ;;
    status)
        get_status
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|reload|condrestart|status}"
        RETVAL=1
esac

exit $RETVAL

