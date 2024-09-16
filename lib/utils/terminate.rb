require_relative 'logger'

module Utils
  class Terminate
    def self.exit_with_error(message)
      Utils::Log.logger.error(message)
      exit(1)
    end
  end
end
