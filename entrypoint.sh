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
else
    # User is not configured, run initial setup in foreground so they can get the URL
    cd /root/.dropbox-dist/dropbox-lnx.x86_64-*
    ./dropboxd
fi

function wait_for_dropbox {
    pidof dropbox >/dev/null
    if [ $? -ne 0 ]; then
        echo "Dropbox process not found yet..."
        sleep 1
        wait_for_dropbox
    fi
}

# Keep looking for the dropbox process for up-to 25 seconds
echo "Start looking for dropbox process"
export -f wait_for_dropbox
timeout 25s /bin/bash -c wait_for_dropbox
if [ $? -ne 0 ]; then
    >&2 echo "Dropbox quit unexpectedly"
    exit 1
fi

# After the dropbox process has started it may randomly restart. I don't know why it does this, but it's just
# another annoying hassle this script has to deal with.
# Find the process and wait for it. If it exits, try and find another process otherwise exit.
function watch_dropbox_pid {
    PID=$(pidof dropbox)
    if [ $? -ne 0 ]; then
        >&2 echo "Dropbox is not running"
        exit 1
    fi
    echo "Dropbox agent running with PID ${PID}, waiting..."
    tail --pid=${PID} -f /dev/null
    echo "Dropbox PID ${PID} exited, finding new PID..."
    sleep 5
    watch_dropbox_pid
}
if [ -f /tmp/dropbox-antifreeze-* ]; then
    tail -n 0 -f /tmp/dropbox-antifreeze-* &
else
    echo "No dropbox log found"
fi
watch_dropbox_pid
