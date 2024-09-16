require 'net/http'
require 'uri'
require 'json'
require 'time'

require_relative '../utils/logger'
require_relative '../utils/terminate'

module API
  class CloudflareAPI
    MAX_RETRIES = 5 # Maximum number of retries on 429
    RATE_LIMIT_WINDOW = 300 # 5 minutes in seconds
    REQUEST_LIMIT = 1200 # Maximum requests in 5 minutes

    @request_count = 0
    @last_reset_time = Time.now

    def self.api_call(method, url, body = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      reset_rate_limit_if_needed
      retries = 0
      Utils::Log.logger.debug("Starting API call: #{method.upcase} #{url}")

      while retries <= MAX_RETRIES
        if rate_limited?
          Utils::Log.logger.warn("Rate limit reached, retrying after #{RATE_LIMIT_WINDOW} seconds...")
          sleep(RATE_LIMIT_WINDOW)
        end

        uri = URI(url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        request = case method
                  when :get
                    Net::HTTP::Get.new(uri)
                  when :post
                    Net::HTTP::Post.new(uri)
                  when :delete
                    Net::HTTP::Delete.new(uri)
                  else
                    Utils::Terminate.exit_with_error("Unsupported HTTP method: #{method}")
                  end

        request['X-Auth-Email'] = CLOUDFLARE_EMAIL
        request['X-Auth-Key'] = CLOUDFLARE_API_KEY
        request['Content-Type'] = 'application/json'
        request.body = body.to_json if body

        response = https.request(request)
        status_code = response.code.to_i

        if status_code == 429
          retries += 1
          Utils::Terminate.exit_with_error("Max retries exceeded for #{url}") if retries > MAX_RETRIES

          sleep_time = calculate_backoff_time(retries)
          Utils::Log.logger.warn("Received 429 Too Many Requests, retrying in #{sleep_time} seconds... (attempt #{retries})")
          sleep(sleep_time)
        elsif status_code.between?(200, 299)
          Utils::Log.logger.debug("Received successful response (#{status_code}), parsing result...")
          @request_count += 1
          return JSON.parse(response.body)['result']
        else
          Utils::Terminate.exit_with_error("HTTP Error #{status_code} when calling #{uri}: #{response.body}")
        end
      end

      Utils::Terminate.exit_with_error("Max retries exceeded for #{url}")
    end

    # Calculate backoff time (in seconds)
    # First retry waits 5 minutes, subsequent retries wait exponentially longer
    def self.calculate_backoff_time(retries)
      initial_delay = RATE_LIMIT_WINDOW # First retry waits 5 minutes (300 seconds)
      sleep_time = initial_delay * (2**(retries - 1)) # Exponential backoff after first retry
      [sleep_time, RATE_LIMIT_WINDOW * MAX_RETRIES].min # Cap backoff to prevent excessively long delays
    end

    def self.rate_limited?
      @request_count >= REQUEST_LIMIT
    end

    def self.reset_rate_limit_if_needed
      return unless Time.now - @last_reset_time > RATE_LIMIT_WINDOW

      @request_count = 0
      @last_reset_time = Time.now
      Utils::Log.logger.info('Rate limit window reset.')
    end
  end
end
