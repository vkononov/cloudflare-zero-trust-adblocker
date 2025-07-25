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
    INITIAL_BACKOFF_OTHER = 10 # Initial backoff time for other errors (10 seconds)

    # Retryable HTTP status codes (excluding 429 which has special handling)
    RETRYABLE_STATUS_CODES = [502, 503, 504, 520, 521, 522, 523, 524].freeze

    @request_count = 0
    @last_reset_time = Time.now

    def self.api_call(method, url, body = nil) # rubocop:disable Metrics/MethodLength
      reset_rate_limit_if_needed
      retries_429 = 0 # rubocop:disable Naming/VariableNumber
      retries_other = 0
      Utils::Log.logger.debug("Starting API call: #{method.upcase} #{url}")

      loop do
        if rate_limited?
          Utils::Log.logger.warn("Rate limit reached, retrying after #{RATE_LIMIT_WINDOW} seconds...")
          sleep(RATE_LIMIT_WINDOW)
        end

        response = make_http_request(method, url, body)
        result = handle_response(response, url, retries_429, retries_other)

        return result[:data] if result[:action] == :return

        retries_429 = result[:retries_429] # rubocop:disable Naming/VariableNumber
        retries_other = result[:retries_other]
      end
    end

    def self.handle_response(response, url, retries_429, retries_other) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Naming/VariableNumber
      status_code = response.code.to_i

      case status_code
      when 429
        retries_429 += 1 # rubocop:disable Naming/VariableNumber
        Utils::Terminate.exit_with_error("Max retries exceeded for 429 errors on #{url}") if retries_429 > MAX_RETRIES

        sleep_time = calculate_429_backoff_time(retries_429)
        Utils::Log.logger.warn("Received 429 Too Many Requests, retrying in #{sleep_time} seconds... (attempt #{retries_429})")
        sleep(sleep_time)

        { action: :continue, retries_429: retries_429, retries_other: retries_other } # rubocop:disable Naming/VariableNumber
      when 200..299
        Utils::Log.logger.debug("Received successful response (#{status_code}), parsing result...")
        @request_count += 1

        { action: :return, data: JSON.parse(response.body)['result'], retries_429: retries_429, retries_other: retries_other } # rubocop:disable Naming/VariableNumber
      when *RETRYABLE_STATUS_CODES
        retries_other += 1
        Utils::Terminate.exit_with_error("Max retries exceeded for HTTP #{status_code} errors on #{url}. Last error: #{response.body}") if retries_other > MAX_RETRIES

        sleep_time = calculate_other_backoff_time(retries_other)
        Utils::Log.logger.warn("Received HTTP #{status_code} error, retrying in #{sleep_time} seconds... (attempt #{retries_other}): #{response.body}")
        sleep(sleep_time)

        { action: :continue, retries_429: retries_429, retries_other: retries_other } # rubocop:disable Naming/VariableNumber
      else
        # Non-retryable errors (4xx client errors, etc.)
        Utils::Terminate.exit_with_error("HTTP Error #{status_code} when calling #{URI(url)}: #{response.body}")
      end
    end

    def self.make_http_request(method, url, body) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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

      https.request(request)
    end

    # Calculate backoff time for 429 errors (unchanged behavior)
    # First retry waits 5 minutes, subsequent retries wait exponentially longer
    def self.calculate_429_backoff_time(retries)
      initial_delay = RATE_LIMIT_WINDOW # First retry waits 5 minutes (300 seconds)
      sleep_time = initial_delay * (2**(retries - 1)) # Exponential backoff after first retry
      [sleep_time, RATE_LIMIT_WINDOW * MAX_RETRIES].min # Cap backoff to prevent excessively long delays
    end

    # Calculate backoff time for other retryable errors (new)
    # Much shorter delays for transient errors
    def self.calculate_other_backoff_time(retries)
      INITIAL_BACKOFF_OTHER * (2**(retries - 1)) # 10s, 20s, 40s
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
