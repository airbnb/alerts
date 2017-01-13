name "#{@hostinfo[:role]}: swap usage > 50%"
message "A #{@hostinfo[:role]} machine is swapping heavily"

applies { @hostinfo[:role] }

notify.groups @hostinfo[:owner_groups]
notify.people @hostinfo[:owners]

metric.datadog_query <<EOQ
avg(last_10m):avg:system.swap.pct_free{chef_role:#{@hostinfo[:role]}} by {host} < 0.5
EOQ

silenced false
