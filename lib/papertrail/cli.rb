require 'optparse'
require 'yaml'
require 'chronic'
require 'ansi/core'

require 'papertrail'
require 'papertrail/connection'
require 'papertrail/cli_helpers'
require 'papertrail/okjson'

module Papertrail
  class Cli
    include Papertrail::CliHelpers

    attr_reader :options, :query_options, :connection

    def initialize
      @options = {
        :configfile => nil,
        :delay  => 2,
        :follow => false,
        :token  => ENV['PAPERTRAIL_API_TOKEN'],
        :color  => :program,
        :force_color => false,
      }

      @query_options = {}
      @query = nil
    end

    def run
      if configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner  = "papertrail - command-line tail and search for Papertrail log management service"
        opts.version = Papertrail::VERSION

        opts.on("-h", "--help", "Show usage") do
          puts opts
          exit
        end
        opts.on("-f", "--follow", "Continue running and printing new events (off)") do
          options[:follow] = true
        end
        opts.on("--min-time MIN", "Earliest time to search from") do |v|
          options[:min_time] = v
        end
        opts.on("--max-time MAX", "Latest time to search from") do |v|
          options[:max_time] = v
        end
        opts.on("-d", "--delay SECONDS", "Delay between refresh (2)") do |v|
          options[:delay] = v.to_i
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-g", "--group GROUP", "Group to search") do |v|
          options[:group] = v
        end
        opts.on("-S", "--search SEARCH", "Saved search to search") do |v|
          options[:search] = v
        end
        opts.on("-s", "--system SYSTEM", "System to search") do |v|
          options[:system] = v
        end
        opts.on("-j", "--json", "Output raw JSON data (off)") do
          options[:json] = true
        end
        opts.on("--color [program|system|all|off]", 
          [:program, :system, :all, :off], "Attribute(s) to colorize based on (program)") do |v|

          options[:color] = v
        end
        opts.on("--force-color", "Force use of ANSI color characters even on non-tty outputs (off)") do
          options[:force_color] = true
        end
        opts.on("-V", "--version", "Display the version and exit") do
          puts "papertrail version #{Papertrail::VERSION}"
          exit
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      unless options[:token]
        abort 'Authentication token not found. Set config file "token" attribute or PAPERTRAIL_API_TOKEN.'
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

      @query ||= ARGV.join ' '

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

      connection.each_event(@query, query_options.merge(:min_time => min_time, :max_time => max_time)) do |event|
        if options[:json]
          $stdout.puts Papertrail::OkJson.encode(event.data)
        else
          display_result(event)
        end
      end
    end

    COLORS = [:cyan, :yellow, :green, :magenta, :red]

    def colorize(event)
      attribs = ""
      if options[:color] == :system || options[:color] == :all
        attribs += event.data["hostname"]
      end
      if options[:color] == :program || options[:color] == :all
        attribs += event.data["program"]
      end

      idx = attribs.hash % 5
      color = COLORS[idx]
      pre  = "#{event.received_at.strftime('%b %e %X')} #{event.data['hostname']} #{event.data['program']}:"
      post = " #{event.data['message']}"
      pre.ansi(color) + post
    end

    def display_colors?
      options[:color] != :off &&
        (options[:force_color] || (STDOUT.isatty && ENV.has_key?("TERM")))
    end

    def display_result(event)
      event_str = display_colors? ? colorize(event) : event.to_s
      $stdout.puts event_str
    end

    def display_results(results)
      if options[:json]
        $stdout.puts Papertrail::OkJson.encode(results.data)
      else
        results.events.each do |event|
          display_result(event)
        end
      end

      $stdout.flush
    end

    def usage
      <<-EOF

  Usage:
    papertrail [-f] [--min-time time] [--max-time time] [-g group] [-S search]
      [-s system] [-d seconds] [-c papertrail.yml] [-j] [--color attributes]
      [--force-color] [--version] [--] [query]

  Examples:
    papertrail -f
    papertrail something
    papertrail 1.2.3 Failure
    papertrail -s ns1 "connection refused"
    papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
    papertrail -f -g Production --color all "(nginx OR pgsql) -accepted"
    papertrail --min-time 'yesterday at noon' --max-time 'today at 4am' -g Production
    papertrail -- -redis

  More: https://github.com/papertrail/papertrail-cli
        https://papertrailapp.com/
  EOF
    end
  end
end
