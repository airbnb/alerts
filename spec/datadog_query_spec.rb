require "spec_helper"

require_relative '../lib/datadog_query_checker'

describe 'DatadogQueryParser' do
  let(:query_parser) {
    DatadogQueryChecker.new
  }

  def valid_query(query)
    expect(query_parser.validate(query)).to be_truthy
  end

  def invalid_query(query)
    expect(query_parser.validate(query)).to be_falsey
  end

  it 'passes basic queries' do
    valid_query('metric{*}')
  end

  it 'rejects basic invalid queries' do
    invalid_query('*')
  end

  it 'passes queries with comma separated scopes' do
    valid_query('metric{host:foo, host:bar}')
    valid_query('metric{host:foo , host:bar}')
    valid_query('metric{host:foo ,host:bar}')
    valid_query('metric{host:foo,host:bar}')
  end

  it 'passes queries with group by' do
    valid_query('metric{host:foo, host:bar} by {host}')
    valid_query('metric{host:foo, host:bar} by {host,zone}')
    valid_query('metric{host:foo, host:bar} by {host, zone}')
    valid_query('metric{host:foo, host:bar} by {host , zone}')
    valid_query('metric{host:foo, host:bar} by {host ,zone}')
  end

  it 'passes queries with space_aggrations' do
    valid_query('avg:metric{*}')
    valid_query('min:metric{*}')
    valid_query('max:metric{*}')
    valid_query('sum:metric{*}')
    valid_query('sum:metric{*} by {host}')
  end


  it 'rejects queries with invalid space_aggrations' do
    invalid_query('mean:metric{*}')
    invalid_query('median:metric{*}')
    invalid_query('mode:metric{*} by {host}')
  end

  it 'passes queries enclosed in parentheses' do
    valid_query('(metric{*})')
    valid_query('(avg:metric{*} by {host})')
  end

  it 'passes queries with arithmetic operators' do
    valid_query('1 + avg:metric{*} by {host}')
    valid_query('1.5 + avg:metric{*} by {host}')
    valid_query('avg:metric{*} by {host} - 1')
    valid_query('avg:metric{*} by {host} - 1.5')
    valid_query('avg:metric{*} by {host} + avg:metric_2{*} by {host}')
    valid_query('avg:metric{*} by {host} + avg:metric_2{*} by {host} / avg:metric_3{*} by {host}')
    valid_query('(avg:metric{*} by {host} + avg:metric_2{*} by {host}) / avg:metric_3{*} by {host}')
  end

  it 'rejects queries with invalid arithmetic operators' do
    invalid_query('avg:metric{*} by {host} % 2')
  end

  it 'passes queries with append functions' do
    valid_query('avg:metric{*}.as_count()')
    valid_query('avg:metric{*} by {host}.as_count()')
    valid_query('avg:metric{*}.as_rate()')
    valid_query('avg:metric{*}.rollup("avg",15)')
    valid_query('avg:metric{*}.rollup(count, 15)')
    valid_query('avg:metric{*}.rollup(count, 15) + 15')
  end

  it 'reject queries with invalid append functions' do
    invalid_query('avg:metric{*}.as_counter()')
    invalid_query('avg:metric{*}.rollup("mean",15)')
  end

  it 'passes queries with functions' do
    valid_query('diff(avg:metric{*})')
    valid_query('ewma_5(avg:metric{*})')
    valid_query('top5(avg:metric{*})')
    valid_query('top(avg:metric{*}, 10, last, asc)')
    valid_query('top_offset(avg:metric{*}, 10, last, asc, 10)')
    valid_query('forecast(avg:metric{*}, median, hourly, 3)')
    valid_query('forecast(avg:metric{*}, median, hourly, 3).as_count()')
    valid_query("anomalies(sum:metric{*}.as_count().rollup(sum,120), 'agile', 2, direction='below')")
  end

  it 'rejects queries with invalid functions' do
    invalid_query('diff(avg:metric{*}')
    invalid_query('bad_function(avg:metric{*})')
    invalid_query('top_5(avg:metric{*})')
    invalid_query('top(avg:metric{*}, 10, last)')
    invalid_query('top_offset(avg:metric{*}, 10, last, asc)')
    invalid_query('forecast(avg:metric{*}, median, monthly, 3)')
    invalid_query('forecast(avg:metric{*}, average, weekly, 3)')
    invalid_query('forecast(avg:metric{*}, median, weekly, 1)')
    invalid_query("anomalies(sum:metric{*}.as_count().rollup(sum, 120), 'invalid', 2, direction='below')")
  end

  it 'passes alerts' do
    valid_query('avg(last_1m):metric{*} > 1')
    valid_query('avg(last_1m):metric{*} != 1.0')
    valid_query('avg(last_1m):min:metric{*} > 1')
    valid_query('avg(last_1m):min:metric{*} + min:metric_2{*}> 1')
    valid_query('avg(last_1m):min:metric{*} + min:metric_2{*}> 1')
    valid_query('change(avg(last_1m), 5m_ago):metric{*} > 1')
    valid_query('pct_change(avg(last_1m), 5m_ago):metric{*} > 1')
    valid_query("avg(last_30m):anomalies(sum:metric{*}.as_count().rollup(sum, 30),'agile',2, direction='below') >= 0.5
")
  end

  it 'rejects bad alerts' do
    invalid_query('median(last_1m):metric{*} > 1')
    invalid_query('avg(last_2m):metric{*} > 1')
    invalid_query('change(avg(last_1m)):metric{*} > 1')
  end

  it 'rejects alerts not using sum time_aggregator with as_count' do
    invalid_query('avg(last_1m):metric{*}.as_count() > 1')
  end

  it 'allows alerts using sum time_aggregator with as_count' do
    valid_query('sum(last_1m):metric{*}.as_count() > 1')
  end

  it 'allows alerts using anomalies with non-sum time_aggregator with as_count' do
    valid_query("avg(last_30m):anomalies(sum:metric{*}.as_count().rollup(sum, 30),'agile',2, direction='below') >= 0.5")
  end
end
