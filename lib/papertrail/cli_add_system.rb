require 'optparse'
require 'yaml'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliAddSystem
    include Papertrail::CliHelpers

    def run
      # Let it slide if we have invalid JSON
      if JSON.respond_to?(:default_options)
        JSON.default_options[:check_utf8] = false
      end

      options = {
        :configfile => nil,
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail-add-system"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-s", "--system SYSTEM", "Name of system to add") do |v|
          options[:system] = v
        end
        opts.on("-i", "--ip-address IP_ADDRESS", "IP address of system") do |v|
          options[:ip] = v
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      raise OptionParser::MissingArgument, 'system' if options[:system].nil?
      raise OptionParser::MissingArgument, 'ip' if options[:ip].nil?

      connection = Papertrail::Connection.new(options)
      
      # Bail if system already exists
      if connection.show_source(options[:system])
        exit 0
      end

      if connection.register_source(options[:system], options[:ip])
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
    papertrail-add-system [-s system] [-i ip-address] [-c papertrail.yml] 

  Example:
    papertrail-add-system -s mysystemname -i 1.2.3.4

  EOF
    end
  end
end
