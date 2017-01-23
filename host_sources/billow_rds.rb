require 'net/http'
require 'uri'
require 'json'

class BillowRds

  include Interferon::Logging

  def initialize(options)
    @billow_url = options['url']
  end


  def list_hosts
    hosts = []
    rds_instances.each do |region, instances|
      instances.each do |instance|
        log.debug "found RDS instance #{instance['dbinstanceIdentifier']}"

        tags = instance['tags']
        tags['owners'] ||= ''
        tags['owner_groups'] ||= ''

        hosts << {
            :source => 'billow_rds',
            :region => region,
            :instance_id => instance['dbinstanceIdentifier'],
            :db_name => instance['dbname'],
            :engine => instance['engine'],
            :engine_version => instance['engineVersion'],

            # metrics
            :allocated_storage => instance['allocatedStorage'],
            :iops => instance['iops'],


            # replication info
            :is_replica => !instance['readReplicaSourceDBInstanceIdentifier'].nil?,
            :replica_source_name => instance['readReplicaSourceDBInstanceIdentifier'],
            :replica_names => instance['readReplicaDBInstanceIdentifiers'].join(','),
            :replicas => instance['readReplicaDBInstanceIdentifiers'].count,


            :owners => tags['owners'].split(','),
            :owner_groups => tags['owner_groups'].split(','),

            :db_env => tags['db_env'],
            :db_role => tags['db_role'],
            :db_cluster => tags['db_cluster'],
        }
      end
    end

    log.info "found #{hosts.size} RDS instances"
    hosts
  end

  private

  def rds_instances
    uri = URI.parse(@billow_url)
    response = Net::HTTP.get_response(uri)
    if response.code.to_i != 200
      raise "Unexpected HTTP status #{response.code}"
    end
    if response['content-type'] != 'application/json'
      raise "Unsupported response content type: #{response['content-type']}"
    end
    JSON.parse(response.body)
  end
end
