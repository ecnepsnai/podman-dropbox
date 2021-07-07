#!/bin/bash

# Clean up any leftovers from an unclean shutdown
rm -f /root/.dropbox/command_socket /root/.dropbox/iface_socket /root/.dropbox/unlink.db /root/.dropbox/dropbox.pid

cd /root
echo 'Updating dropbox...'
python3 setup.py update
if [ $? -ne 0 ]; then
    >&2 echo "Dropbox failed to update"
    exit 1
fi
rm -f /tmp/dropbox-antifreeze-*

if [ -f /root/.dropbox/instance1/config.dbx ]; then
    # User is already configured, just start the agent
    python3 setup.py start
    sleep 2
else
    # User is not configured, run initial setup in foreground so they can get the URL
    cd /root/.dropbox-dist/dropbox-lnx.x86_64-*
    ./dropboxd
fi

# The dropboxd executable will exit after it's forked off the backend daemon
# annoyingly, there is no way to tell dropbox to run in the foreground
# so check if it's runnin in the background, and if it is then wait for the pid
ps aux | grep dropbox-lnx | grep -v grep >/dev/null 2>&1
if [ $? -ne 0 ]; then
    >&2 echo "Dropbox quit unexpectedly"
    exit 1
fi

PID=$(ps -o pid:1,cmd:1 | grep dropbox-lnx | grep -v grep | cut -d ' ' -f1)
echo "Dropbox agent running with PID ${PID}, waiting..."
tail -n 0 -f /tmp/dropbox-antifreeze-*
