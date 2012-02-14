require 'optparse'
require 'yaml'

require 'papertrail/connection'

module Papertrail
  class Cli
    def run
      options = {
        :configfile => nil,
        :delay  => 10,
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
      end

      if options[:group]
        query_options[:group_id] = connection.find_id_for_group(options[:group])
      end

      search_query = connection.query(ARGV[0], query_options)

      if options[:follow]
        loop do
          search_query.search.events.each do |event|
            $stdout.puts event
          end
          $stdout.flush
          sleep options[:delay]
        end
      else
        search_query.search.events.each do |event|
          $stdout.puts event
        end
      end
    end

    def find_configfile
      if File.exists?(path = File.expand_path('.papertrail.yml'))
        return path
      end
      if File.exists?(path = File.expand_path('~/.papertrail.yml'))
        return path
      end

      false
    end

    def load_configfile(file_path)
      configfile_options = open(file_path) { |f| YAML.load(f) }
      symbolize_keys(configfile_options)
    end

    def symbolize_keys(hash)
      new_hash = {}
      hash.each_key do |key|
        new_hash[(key.to_sym rescue key) || key] = hash[key]
      end

      new_hash
    end

    def usage
      <<-EOF

  Usage: papertrail [-f] [-d seconds] [-c /path/to/papertrail.yml] [query]

  Examples:
    papertrail -f
    papertrail something
    papertrail 1.2.3 Failure
    papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
    papertrail -f -d 10 "ns1 OR 'connection refused'"

  More: https://papertrailapp.com/

  EOF
    end
  end
end