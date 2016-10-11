require 'optparse'
require 'yaml'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliAddUser
    include Papertrail::CliHelpers

    def run
      options = {
        :configfile => nil,
        :token => ENV['PAPERTRAIL_API_TOKEN'],
        :read_only => 1,
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail-add-user"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-e", "--email EMAIL", "Email address of user to add") do |v|
          options[:email] = v
        end
        opts.on("--admin", "Add the user with full access") do |v|
          options[:read_only] = 0
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      raise OptionParser::MissingArgument, 'email' if options[:email].nil?

      connection = Papertrail::Connection.new(options)

      if connection.add_user(options[:email], options[:read_only])
        exit 0
      end

      exit 1
    rescue OptionParser::ParseError => e
      puts "Error: #{e}"
      puts usage
      exit 1
    rescue Net::HTTPServerException => e
      output_http_error(e)
      exit 1
    end

        def usage
      <<-EOF

  Usage:
    papertrail-add-user [-e email] [--admin] [-c papertrail.yml]

  Example:
    papertrail-add-user -e foo@example.com --admin

  EOF
    end
  end
end
