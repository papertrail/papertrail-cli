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
                "Get newest N archive files") do |v|
          options[:newest] = v
        end
        opts.on("--min-time MIN", "Get only entries after MIN") do |v|
          options[:min_time] = parse_time(v)
        end
        opts.on("--max-time MAX", "Get only entries before MAX") do |v|
          options[:max_time] = parse_time(v)
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

      seconds_per_day = 60 * 60 * 24
      end_date = (options[:max_time] + seconds_per_day) or Time.now
      if options[:newest]
        start_date = Time.now - options[:newest] * seconds_per_day
        end_date = Time.now # newest and max-time together don't make sense together
      elsif options[:min_time]
        start_date = options[:min_time]
      else
        raise ArgumentError, "Either :newest or :min-time must be specified"
      end

      days = ((end_date - start_date) / seconds_per_day).floor

      days.times do |offset|
        d = (start_date + offset * seconds_per_day).strftime("%Y-%m-%d")
        puts d
        connection.connection.download("archives/#{d}/download", "#{d}.tgz")
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
