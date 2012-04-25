require 'optparse'
require 'yaml'

require 'papertrail/connection'

module Papertrail
  class Cli
    def run
      options = {
        :configfile => File.expand_path('~/.papertrail.yml'),
        :delay  => 2,
        :follow => false
      }

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

      credentials = open(options[:configfile]) do |f|
        YAML.load(f)
      end

      if credentials['token']
        connection = Papertrail::Connection.new(:token => credentials['token'])
      else
        connection = Papertrail::Connection.new(:username => credentials['username'], :password => credentials['password'])
      end

      query_options = {}

      if options[:system]
        query_options[:system_id] = connection.find_id_for_source(options[:system])
        unless query_options[:system_id]
          puts "System \"#{options[:system]}\" not found"
          exit(-1)
        end
      end

      if options[:group]
        query_options[:group_id] = connection.find_id_for_group(options[:group])
        unless query_options[:group_id]
          puts "Group \"#{options[:group]}\" not found"
          exit(-1)
        end
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

    def usage
      <<-EOF

  Usage: 
    papertrail [-f] [-s system] [-g group] [-d seconds] [-c papertrail.yml] [query]

  Examples:
    papertrail -f
    papertrail something
    papertrail 1.2.3 Failure
    papertrail -s ns1 "connection refused"
    papertrail -f "(www OR db) (nginx OR pgsql) -accepted"
    papertrail -f -g Production "(nginx OR pgsql) -accepted"

  More: https://papertrailapp.com/

  EOF
    end
  end
end