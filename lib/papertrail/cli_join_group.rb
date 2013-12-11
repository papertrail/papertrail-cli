require 'optparse'
require 'yaml'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliJoinGroup
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
        opts.banner = "papertrail-join-group"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-s", "--system SYSTEM", "Name of system to add to group") do |v|
          options[:system] = v
        end
        opts.on("-g", "--group GROUP", "Name of group to join") do |v|
          options[:group] = v
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      raise OptionParser::MissingArgument, 'system' if options[:system].nil?
      raise OptionParser::MissingArgument, 'group' if options[:group].nil?

      connection = Papertrail::Connection.new(options)

      if connection.join_group(options[:system], options[:group])
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
    papertrail-join-group [-s system] [-g group] [-c papertrail.yml]

  Example:
    papertrail-join-group -s mymachine -g mygroup

  EOF
    end
  end
end
