require 'optparse'
require 'yaml'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliAddSystem
    include Papertrail::CliHelpers

    attr_reader :program_name

    def run
      options = {
        :configfile => nil,
        :token => ENV['PAPERTRAIL_API_TOKEN'],
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        @program_name = opts.program_name

        opts.banner = "Usage: #{opts.program_name} [OPTION]..."

        opts.separator ''

        opts.separator "Options:"

        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-s", "--system SYSTEM", "Name of system to add") do |v|
          options[:system] = v
        end
        opts.on("-n", "--hostname HOSTNAME", "Hostname which can be used to filter",
            "events from the same IP by syslog hostname") do |v|
          options[:hostname] = v
        end

        opts.separator ''
        opts.separator 'Host Settings:'

        opts.on("-i", "--ip-address IP_ADDRESS", "IP address of system") do |v|
          options[:ip_address] = v
        end

        opts.on("--destination-port PORT", "Destination port") do |v|
          options[:destination_port] = v
        end

        opts.separator ''
        opts.separator "  Note: only one of --ip-address or --destination-port must be specified"


        opts.separator ''
        opts.separator "Common options:"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end

        opts.separator ''
        opts.separator 'Example:'
        opts.separator "    $ #{opts.program_name} --system mysystemname --destination-port 39273"
        opts.separator "    $ #{opts.program_name} --system mysystemname --ip-address 1.2.3.4"

      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      unless options[:system]
        error "The --system argument must be specified"
      end

      unless options[:ip_address] || options[:destination_port]
        error 'Either --ip-address or --destination-port most be provided'
      end

      Papertrail::Connection.new(options).start do |connection|
        # Bail if system already exists
        existing = connection.show_source(options[:system])
        if existing && existing['name'].upcase == options[:system].upcase
          exit 0
        end

        if options[:destination_port] && !options[:hostname]
          options[:hostname] = options[:system]
        end

        if connection.register_source(options[:system], options)
          exit 0
        end
      end

      exit 1
    rescue OptionParser::ParseError => e
      error(e, true)
      exit 1
    rescue Net::HTTPServerException => e
      output_http_error(e)
      exit 1
    end

    def error(message, try_help = false)
      puts "#{program_name}: #{message}"
      if try_help
        puts "Try `#{program_name} --help' for more information."
      end
      exit(1)
    end
  end
end
