require 'open-uri'
require 'json'

class BillowSqs
  JSON_CONTENT_TYPE  = "application/json"

  def initialize(options)
    @billow_url = options['url']
  end

  def list_hosts
    billow_list_sqs_queues.map do |queue|
      unless queue.has_key?(:queueArn)
        log.warn "Billow SQS entry is missing queueArn member, skipping it: %s" % queue.inspect
        next
      end

      queue_arn = sqs_arn_to_hash queue[:queueArn]
      {
        :source => 'billow_sqs',
        :url => queue[:url],
        :queue_name => queue_arn[:resource],
        :region => queue_arn[:region],
        :account => queue_arn[:account],
      }
    end
  end

  private

  # AWS ARN format:
  # http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-arns
  def sqs_arn_to_hash(arn)
    items = /^arn:(.+?):(.+?):(.+?):(.+?):(.+?)(?:[\/:]|$)(.+)?$/.match(arn)

    if items
      {
        :partition => items[1],
        :service => items[2],
        :region => items[3],
        :account => items[4],
        :resource => items[6].nil? ? items[5] : items[6],
        :resource_type => items[6].nil? ? nil : items[5],
      }
    else
      raise StandardError, "Invalid AWS ARN string: %s" % arn
    end
  end

  def billow_list_sqs_queues
    billow_sqs_endpoint = "%s/sqs" % @billow_url
    response = open(billow_sqs_endpoint, "Content-Type" => JSON_CONTENT_TYPE)

    if response.content_type != JSON_CONTENT_TYPE
      raise StandardError, "Unexpected response from Billow."
    end

    JSON.parse response.string, :symbolize_names => true
  end
end
