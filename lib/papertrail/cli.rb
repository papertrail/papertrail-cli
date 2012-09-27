require 'optparse'
require 'yaml'
require 'chronic'

require 'papertrail/connection'
require 'papertrail/cli_helpers'

module Papertrail
  class Cli
    include Papertrail::CliHelpers

    def run
      # Let it slide if we have invalid JSON
      if JSON.respond_to?(:default_options)
        JSON.default_options[:check_utf8] = false
      end

      options = {
        :configfile => nil,
        :delay  => 2,
        :follow => false
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail - command-line tail and search for Papertrail log management service"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-f", "--follow", "Continue running and print new events (off)") do |v|
          options[:follow] = true
        end
        opts.on("-d", "--delay SECONDS", "Delay between refresh (2)") do |v|
          options[:delay] = v.to_i
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-s", "--system SYSTEM", "System to search") do |v|
          options[:system] = v
        end
        opts.on("-g", "--group GROUP", "Group to search") do |v|
          options[:group] = v
        end
        opts.on("-j", "--json", "Output raw json data") do |v|
          options[:json] = true
        end
        opts.on("--min-time MIN", "Earliest time to search from.") do |v|
          options[:min_time] = v
        end
        opts.on("--max-time MAX", "Latest time to search from.") do |v|
          options[:max_time] = v
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      connection = Papertrail::Connection.new(options)

      query_options = {}

      if options[:system]
        query_options[:system_id] = connection.find_id_for_source(options[:system])
        unless query_options[:system_id]
          abort "System \"#{options[:system]}\" not found"
        end
      end

      if options[:group]
        query_options[:group_id] = connection.find_id_for_group(options[:group])
        unless query_options[:group_id]
          abort "Group \"#{options[:group]}\" not found"
        end
      end

      set_min_max_time!(options, query_options)

      search_query = connection.query(ARGV[0], query_options)

      if options[:follow]
        loop do
          if options[:json]
            $stdout.puts search_query.search.data.to_json
          else
            search_query.search.events.each do |event|
              $stdout.puts event
            end
          end
          $stdout.flush
          sleep options[:delay]
        end
      else
        if options[:json]
          $stdout.puts search_query.search.data.to_json
        else
          search_query.search.events.each do |event|
            $stdout.puts event
          end
        end
      end
    end

    def usage
      <<-EOF

  Usage: 
    papertrail [-f] [-s system] [-g group] [-d seconds] [-c papertrail.yml] [-j] [--min-time mintime] [--max-time maxtime] [query]

  Examples:
    papertrail -f
    papertrail something
    papertrail 1.2.3 Failure
    papertrail -s ns1 "connection refused"
    papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
    papertrail -f -g Production "(nginx OR pgsql) -accepted"
    papertrail -g Production --min-time 'yesterday at noon' --max-time 'today at 4am'

  More: https://papertrailapp.com/

  EOF
    end
  end
end
