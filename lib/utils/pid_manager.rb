require 'fileutils'

module Utils
  class PidManager
    def initialize(pid_file_name = 'instance.pid')
      @pid_dir = File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'pids')
      FileUtils.mkdir_p(@pid_dir)
      @pid_file = File.join(@pid_dir, pid_file_name)
    end

    # Ensure only one instance of the script runs
    def check_and_write_pid # rubocop:disable Metrics/MethodLength
      if pid_exists?
        old_pid = read_pid
        if process_running?(old_pid)
          puts "Another instance of the script is already running (PID: #{old_pid}). Exiting."
          exit(1)
        else
          # Remove stale PID file
          remove_pid_file
        end
      end

      write_pid
      register_cleanup
    end

    private

    # Check if the PID file exists
    def pid_exists?
      File.exist?(@pid_file)
    end

    # Read the PID from the file
    def read_pid
      File.read(@pid_file).to_i
    end

    # Write the current PID to the file
    def write_pid
      File.open(@pid_file, 'w') { |f| f.puts Process.pid }
    end

    # Register a callback to remove the PID file on exit
    def register_cleanup
      at_exit { remove_pid_file if File.exist?(@pid_file) }
    end

    # Remove the PID file
    def remove_pid_file
      File.delete(@pid_file)
    end

    # Check if the process with the given PID is still running
    def process_running?(pid)
      return false if pid <= 0

      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      true
    end
  end
end
