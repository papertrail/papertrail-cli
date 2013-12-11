require 'optparse'
require 'yaml'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliRemoveSystem
    include Papertrail::CliHelpers

    def run
      options = {
        :configfile => nil,
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail-remove-system"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-s", "--system SYSTEM", "Name of system to remove") do |v|
          options[:system] = v
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      raise OptionParser::MissingArgument, 'system' if options[:system].nil?

      connection = Papertrail::Connection.new(options)

      if connection.unregister_source(options[:system])
        exit 0
      end

      exit 1
    rescue OptionParser::ParseError => e
      puts "Error: #{e}"
      puts usage
      exit 1
    end

    def usage
      <<-EOF

  Usage:
    papertrail-remove-system [-s system] [-c papertrail.yml]

  Example:
    papertrail-remove-system -s mysystemname

  EOF
    end
  end
end
