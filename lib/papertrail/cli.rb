require 'optparse'
require 'yaml'
require 'chronic'

require 'papertrail/connection'
require 'papertrail/cli_helpers'

module Papertrail
  class Cli
    include Papertrail::CliHelpers

    attr_reader :options, :query_options, :connection

    def initialize
      @options = {
        :configfile => nil,
        :delay  => 2,
        :follow => false,
        :token  => ENV['PAPERTRAIL_API_TOKEN']
      }

      @query_options = {}
      @query = nil
    end

    def run
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
        opts.on("-S", "--search SEARCH", "Saved search to search") do |v|
          options[:search] = v
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

      @connection = Papertrail::Connection.new(options)

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

      if options[:search]
        search = connection.find_search(options[:search], query_options[:group_id])
        unless search
          abort "Search \"#{options[:search]}\" not found"
        end

        query_options[:group_id] ||= search['group_id']
        @query = search['query']
      end

      @query ||= ARGV[0]

      if options[:follow]
        search_query = connection.query(@query, query_options)

        loop do
          display_results(search_query.search)
          sleep options[:delay]
        end
      elsif options[:min_time]
        query_time_range
      else
        set_min_max_time!(options, query_options)
        search_query = connection.query(@query, query_options)
        display_results(search_query.search)
      end
    end

    def query_time_range
      min_time = parse_time(options[:min_time])

      if options[:max_time]
        max_time = parse_time(options[:max_time])
      end

      search_results = connection.query(@query, query_options.merge(:min_time => min_time.to_i, :tail => false)).search

      loop do
        search_results.events.each do |event|
          # If we've found an event beyond what we were looking for, we're done
          if max_time && event.received_at > max_time
            break
          end

          if options[:json]
            $stdout.puts event.data.to_json
          else
            $stdout.puts event
          end
        end

        # If we've found the end of what we're looking for, we're done
        if max_time && search_results.max_time_at > max_time
          break
        end

        if search_results.reached_end?
          break
        end

        # Perform the next search
        search_results = connection.query(@query, query_options.merge(:min_id => search_results.max_id, :tail => false)).search
      end
    end

    def display_results(results)
      if options[:json]
        $stdout.puts results.data.to_json
      else
        results.events.each do |event|
          $stdout.puts event
        end
      end

      $stdout.flush
    end


    def usage
      <<-EOF

  Usage:
    papertrail [-f] [-s system] [-g group] [-S search] [-d seconds] \
      [-c papertrail.yml] [-j] [--min-time time] [--max-time time] [query]

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
