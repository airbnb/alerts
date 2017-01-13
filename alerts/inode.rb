name "Running out of inodes"

message <<EOM
We are running out of inodes on some instances.

`df -i` can be used to look up the current inode utilization. Note that a
percentage is reserved for the system, so even if we don't
hit 100%, we can still run into "No space left on device" errors.
EOM

applies true

notify.groups ['sre']

metric.datadog_query <<EOQ
min(last_10m):max:system.fs.inodes.in_use{*} by {chef_role,device} > 0.9
EOQ

notify_no_data false
silenced false
