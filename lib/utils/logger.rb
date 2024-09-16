require 'logger'
require 'fileutils'

module Utils
  class Log
    LOG_DIRECTORY = 'log'.freeze
    LOG_FILE = File.join(LOG_DIRECTORY, 'application.log')

    def self.logger # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @logger ||= begin
        # Ensure the log directory exists
        FileUtils.mkdir_p(LOG_DIRECTORY)

        # Create log file and stdout loggers
        stdout_logger = Logger.new($stdout)
        file_logger = Logger.new(LOG_FILE)

        # Set log level from environment variable, default to DEBUG if not set
        log_level = ENV.fetch('LOG_LEVEL', 'info').upcase
        stdout_logger.level = file_logger.level = Logger.const_get(log_level)

        # Create a multi-logger that logs to both stdout and the file
        multi_logger = Logger.new($stdout)
        multi_logger.extend(Module.new do
          define_method(:add) do |severity, message = nil, progname = nil, &block|
            stdout_logger.add(severity, message, progname, &block)
            file_logger.add(severity, message, progname, &block)
          end
        end)

        multi_logger
      end
    end
  end
end
