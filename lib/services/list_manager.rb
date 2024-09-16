require_relative '../api/cloudflare_api'
require_relative '../utils/logger'

module Services
  class ListManager
    def self.fetch_existing_lists
      Utils::Log.logger.info('Retrieving existing lists...')
      API::CloudflareAPI.api_call(:get, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/lists")
    end

    def self.create_list(name, description, domains)
      Utils::Log.logger.info("Creating list '#{name}'...")
      items = domains.map { |domain| { 'value' => domain } }
      body = { name: name, description: description, type: 'DOMAIN', items: items }
      API::CloudflareAPI.api_call(:post, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/lists", body)
    end

    def self.delete_list(list_id)
      Utils::Log.logger.info("Deleting list with ID #{list_id}...")
      API::CloudflareAPI.api_call(:delete, "https://api.cloudflare.com/client/v4/accounts/#{CLOUDFLARE_ACCOUNT_ID}/gateway/lists/#{list_id}")
    end
  end
end
