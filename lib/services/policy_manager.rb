require_relative '../api/cloudflare_api'
require_relative '../utils/logger'

module Services
  class PolicyManager
    def self.fetch_existing_policies
      Utils::Log.logger.info('Retrieving existing policies...')
      API::CloudflareAPI.api_call(:get, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/rules")
    end

    def self.create_policy(name, description, lists)
      Utils::Log.logger.info("Creating policy '#{name}'...")
      traffic_expression = lists.map { |list| "dns.fqdn in $#{list['id']}" }.join(' or ')
      body = { name: name, description: description, action: 'block', filters: ['dns'], enabled: true, traffic: traffic_expression, precedence: 1 }
      API::CloudflareAPI.api_call(:post, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/rules", body)
    end

    def self.delete_policy(policy_id)
      Utils::Log.logger.info("Deleting policy with ID #{policy_id}...")
      API::CloudflareAPI.api_call(:delete, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/rules/#{policy_id}")
    end
  end
end
