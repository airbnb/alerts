require 'treetop'

class DatadogQueryChecker
  Treetop.load 'datadog.treetop'

  attr_reader :failure_reason

  def initialize
    @datadog_query_parser = DatadogQueryParser.new
    @failure_reason = ''
  end

  def validate(query)
    parsed_query = @datadog_query_parser.parse(query)
    if parsed_query.nil?
      @failure_reason = @datadog_query_parser.failure_reason
      false
    elsif parsed_query.has_conflicts
      @failure_reason = parsed_query.has_conflicts
      false
    else
      true
    end
  end

end
