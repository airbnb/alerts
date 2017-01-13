name "RDS instance #{@hostinfo[:instance_id]}: FileSystem disk is used up"

message "RDS instance id #{@hostinfo[:instance_id]} has used up most of its filesystem disk space."

applies do
  @hostinfo[:source] == 'billow_rds' &&
    @hostinfo[:db_env] == 'production' &&
    ['master', 'replica'].include?(@hostinfo[:db_role])
end

notify.people ['yourfriendlydba@yourcompany.com']

time_window = 15
threshold = 95
filesystem_disk_metric = "aws.rds.filesystem.usedPercent{dbinstanceidentifier:#{@hostinfo[:instance_id]}}"

metric.datadog_query <<EOQ
avg(last_#{time_window}m):avg: #{filesystem_disk_metric} > #{threshold}
EOQ

notify_no_data true
no_data_timeframe 5
silenced false
