#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'interferon'
require_relative '../lib/datadog_query_checker'

class AlertsRepoDatadogQueryChecker
  def initialize
    @datadog_query_checker = DatadogQueryChecker.new
  end

  def run
    errors = 0
    Dir.glob(File.join('alerts', '*.rb')) do |alert_file|
      begin
        alert = Interferon::Alert.new(alert_file).evaluate({:owner_groups => [],
                                                            :owners => [],
                                                            :role => "machine",
                                                            :metric => 'avg(last_10m)',
                                                            :read_capacity=> 1,
                                                            :write_capacity=> 1,
                                                            :provider_machine_count => 1,
                                                            :iops => 1,
                                                            :allocated_storage => 1,
                                                            :threshold => '10'
        })
      rescue StandardError => e
        errors += 1
        puts "error reading alert file #{alert_file}: #{e}\n"
        puts "Backtrace:\n#{e.backtrace.join("\n\t")}"
        next
      end

      dd_query = alert['metric']['datadog_query'].split.join('').strip
      if !@datadog_query_checker.validate(dd_query)
        errors += 1
        puts "Invalid datadog query in #{alert_file}: #{dd_query} #{@datadog_query_checker.failure_reason}"
      end
    end

    exit(errors == 0 ? 0 : 1)
  end
end

dd_query_checker = AlertsRepoDatadogQueryChecker.new
dd_query_checker.run()
