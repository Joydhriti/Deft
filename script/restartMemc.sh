#!/bin/bash
addr=$(head -1 ../memcached.conf)  # 10.10.15.73
port=$(awk 'NR==2{print}' ../memcached.conf)  # 11211

# Check if running on the memcached host (ns23)
if [ "$(hostname -I | awk '{print $1}')" = "$addr" ]; then
    # Local execution (no SSH)
    # Kill old memcached
    if [ -f /tmp/memcached.pid ]; then
        kill $(cat /tmp/memcached.pid) 2>/dev/null
    fi
    # Clear caches
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    # Launch memcached as castl
    memcached -u castl -l ${addr} -p ${port} -c 10000 -d -P /tmp/memcached.pid
else
    # Remote execution (from ns26)
    # Kill old memcached
    ssh castl@${addr} "if [ -f /tmp/memcached.pid ]; then kill \$(cat /tmp/memcached.pid); fi"
    # Clear caches (requires sudo on remote)
    ssh castl@${addr} "sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'"
    # Launch memcached as castl
    ssh castl@${addr} "memcached -u castl -l ${addr} -p ${port} -c 10000 -d -P /tmp/memcached.pid"
fi

# Wait for memcached to start
sleep 1

# Initialize memcached
echo -e "set ServerNum 0 0 1\r\n0\r\nquit\r" | nc ${addr} ${port}
echo -e "set ClientNum 0 0 1\r\n0\r\nquit\r" | nc ${addr} ${port}
