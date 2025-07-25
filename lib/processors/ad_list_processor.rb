require 'net/http'
require 'uri'

require_relative '../utils/logger'

module Processors
  class AdListProcessor
    # Regex to match valid IPv4 addresses (to reject them as hostnames)
    IPV4_REGEX = /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/.freeze

    # Regex to match invalid IP-like patterns (e.g., 103.103.69.97.12)
    INVALID_IP_LIKE_REGEX = /\A(?:\d+\.){4,}\d+\z/.freeze

    # Improved hostname regex that ensures proper domain structure
    HOSTNAME_REGEX = /\A
      (?=.{1,253}\z) # Overall length up to 253 chars
      (?!.*\.\.) # No consecutive dots
      (?![.-]) # Cannot start with dot or hyphen
      (?!.*[.-]\z) # Cannot end with dot or hyphen
      [a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])? # First label
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
      # Reject valid IPv4 addresses (they're not hostnames)
      return false if hostname.match?(IPV4_REGEX)

      # Reject invalid IP-like patterns (e.g., 103.103.69.97.12)
      return false if hostname.match?(INVALID_IP_LIKE_REGEX)

      # Reject hostnames that are all numeric labels (likely malformed IPs)
      labels = hostname.split('.')
      return false if labels.length > 1 && labels.all? { |label| label.match?(/\A\d+\z/) }

      # Check against the hostname regex
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
