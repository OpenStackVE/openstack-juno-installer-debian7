#!/bin/sh
### BEGIN INIT INFO
# Provides:          tgtd
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      
# Short-Description: Start the iSCSI target server tgt
# Description:       iSCSI target server tgt (http://stgt.sf.net)
### END INIT INFO

set -e

TGTD="/usr/sbin/tgtd"
TGTADMIN="/usr/sbin/tgt-admin"
DEFAULTS="/etc/default/tgt"

# Check for daemon presence
[ -x "$TGTD" ] || exit 0

OPTIONS=""
MODULES=""
# Include tgtd defaults if available
[ -r "$DEFAULTS" ] && . "$DEFAULTS"

# Get lsb functions
. /lib/lsb/init-functions

case "$1" in
  start)
    log_begin_msg "Starting iSCSI target (tgt) services..."
    start-stop-daemon --start --quiet --oknodo --exec "$TGTD" -- $OPTIONS
    [ -x "$TGTADMIN" ] && $TGTADMIN -e
    log_end_msg $?
    ;;
  stop)
    log_begin_msg "Stopping iSCSI target (tgt) services..."
    start-stop-daemon --stop --quiet --oknodo --retry 2 --exec "$TGTD"
    log_end_msg $?
    ;;
  restart)
    $0 stop
    sleep 1
    $0 start
    ;;
  reload|force-reload)
    log_begin_msg "Reloading iSCSI target (tgt) services..."
    start-stop-daemon --stop --signal 1 --exec "$TGTD"
    log_end_msg $?
    ;;
  status)
    status_of_proc "$TGTD" tgtd
    ;;
  *)
    log_success_msg "Usage: /etc/init.d/tgt {start|stop|restart|reload|force-reload|status}"
    exit 1
esac
