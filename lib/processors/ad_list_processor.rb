require 'net/http'
require 'uri'

require_relative '../utils/logger'

module Processors
  class AdListProcessor
    def self.download_ad_list(url) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      Utils::Log.logger.info("Downloading ad list from #{url}...")
      uri = URI.parse(url)
      Utils::Log.logger.debug("Parsed URI: #{uri}")

      response = Net::HTTP.get_response(uri)
      Utils::Log.logger.debug("Received HTTP response. Status: #{response.code}, Body length: #{response.body.length}")

      if response.is_a?(Net::HTTPSuccess)
        Utils::Log.logger.info('Successfully downloaded ad list.')
        response.body
      else
        Utils::Terminate.exit_with_error("Failed to download ad list. HTTP Status: #{response.code}")
      end
    end

    def self.process_ad_list(ad_list_content, exclusions) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      Utils::Log.logger.info('Processing ad list content...')
      Utils::Log.logger.debug("Ad list content length: #{ad_list_content.length}, exclusions: #{exclusions}")

      hostnames = []
      ad_list_content.each_line do |line|
        original_line = line.strip
        next if original_line.empty? || original_line.start_with?('#')

        line = original_line.split('#').first.strip

        case line
        when /^(\d{1,3}\.){3}\d{1,3}\s+(.+)$/
          hostname = ::Regexp.last_match(2).strip
          next if hostname =~ /^(\d{1,3}\.){3}\d{1,3}$/

          hostnames << hostname unless exclusions.include?(hostname)
        when /^::1\s+(.+)$/
          hostname = ::Regexp.last_match(1).strip
          hostnames << hostname unless exclusions.include?(hostname)
        when /^\S+$/
          hostnames << line unless exclusions.include?(line)
        else
          Utils::Log.logger.warn("Unrecognized line in ad list: #{original_line}")
        end
      end

      hostnames.uniq
    end
  end
end
