name "#{@hostinfo[:role]}: load spiking over 95% for 5 minutes"

message "One-minute load is over .95 per CPU on a #{@hostinfo[:role]} machine"

omit_substrings = %w(
  -development
  -staging
  -test
)

should_apply = @hostinfo[:role] &&
               omit_substrings.select { |p| @hostinfo[:role].include?(p) }.empty?

applies {
  should_apply
}

notify.groups @hostinfo[:owner_groups]
notify.people @hostinfo[:owners]

metric.datadog_query <<EOQ
min(last_5m):avg:system.load.norm.1{chef_role:#{@hostinfo[:role]}} > 0.95
EOQ

silenced false
