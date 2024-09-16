require_relative '../utils/logger'

module Processors
  class ExclusionsLoader
    def self.load_exclusions(file)
      Utils::Log.logger.info("Loading exclusions from #{file}...")
      exclusions = []
      if File.exist?(file)
        exclusions = File.read(file).split("\n").map(&:strip).reject(&:empty?)
        Utils::Log.logger.info("Loaded #{exclusions.size} exclusions.")
      else
        Utils::Log.logger.warn('Exclusions file not found. Proceeding without exclusions.')
      end
      exclusions
    end
  end
end
