require 'optparse'
require 'yaml'
require 'time'
require 'chronic'

require 'papertrail/cli_helpers'
require 'papertrail/connection'

module Papertrail
  class CliArchives
    include Papertrail::CliHelpers

    def run
      options = {
        configfile: nil,
        token: ENV['PAPERTRAIL_API_TOKEN'],
      }
      
      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail-archives"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("--newest N", OptionParser::DecimalInteger,
                "Get newest N entries") do |v|
          options[:newest] = v
        end
        opts.on("--min-time MIN", "Get only entries after MIN") do |v|
          options[:min_time] = Time.parse(v)
        end
        opts.on("--max-time MAX", "Get only entries before MAX") do |v|
          options[:max_time] = Time.parse(v)
        end

        opts.separator usage
      end.parse!

      if options[:newest].nil? && options[:min_time].nil? && options[:max_time].nil?
        raise OptionParser::MissingArgument, "At least one of --newest, "\
                                             "--min-time or --max-time "\
                                             "is required"
      end
        
      
      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      connection = Papertrail::Connection.new(options)

      connection.each_event(nil, options) do |event|
        puts event # for testing
      end

    end

    def usage
      <<-EOF
  Usage:
    papertrail-archives [--newest N] [--min-time MIN] [--max-time MAX]

  Example:
    papertrail-archives --min-time "11-12-15 14:00"

  EOF
    end

  end
end
