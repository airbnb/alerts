name "#{@hostinfo[:role]}: free memory below 5%"

message <<EOM
A #{@hostinfo[:role]} machine is critically low on memory. Low memory
conditions are dangerious because they could cause the OOM killer to activate.
The OOM killer is unpredictable, and can kill all sorts of processes which are
very important to to the proper functioning of the system.

You should investigate what is causing the box to run low on memory. Some actionable
steps you can take to resolve this alert are:

* Fix memory leaks in the applications running on the box
* Spin up your service on instances with larger memory sizes
EOM

applies { @hostinfo[:role] }

notify.groups @hostinfo[:owner_groups]
notify.people @hostinfo[:owners]

metric.datadog_query <<EOQ
avg(last_5m):avg:system.mem.pct_usable{chef_role:#{@hostinfo[:role]}} by {host} < 0.05
EOQ

silenced false
