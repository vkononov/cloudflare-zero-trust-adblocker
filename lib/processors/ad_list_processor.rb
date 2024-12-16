require 'net/http'
require 'uri'

require_relative '../utils/logger'

module Processors
  class AdListProcessor
    HOSTNAME_REGEX = /\A
      (?=.{1,253}\z) # Overall length up to 253 chars
      [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])? # One hostname label
      (?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)* # Additional labels
    \z/x.freeze

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

    def self.valid_hostname?(hostname)
      hostname.match?(HOSTNAME_REGEX)
    end

    def self.process_ad_list(ad_list_content, exclusions) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      Utils::Log.logger.info('Processing ad list content...')
      Utils::Log.logger.debug("Ad list content length: #{ad_list_content.length}, exclusions: #{exclusions}")

      hostnames = []
      ad_list_content.each_line do |line|
        original_line = line.strip
        next if original_line.empty? || original_line.start_with?('#')

        # Remove comments
        line = original_line.split('#').first.strip

        hostname = case line
                   when /^(\d{1,3}\.){3}\d{1,3}\s+(.+)$/
                     candidate = ::Regexp.last_match(2).strip
                     candidate =~ /^(\d{1,3}\.){3}\d{1,3}$/ ? nil : candidate
                   when /^::1\s+(.+)$/
                     ::Regexp.last_match(1).strip
                   when /^\S+$/
                     line
                   else
                     Utils::Log.logger.warn("Unrecognized line in ad list: #{original_line}")
                     nil
                   end

        next if hostname.nil? || exclusions.include?(hostname)

        if valid_hostname?(hostname)
          hostnames << hostname
        else
          Utils::Log.logger.warn("Invalid hostname encountered: #{hostname}")
        end
      end

      hostnames.uniq
    end
  end
end
