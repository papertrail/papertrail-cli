require 'optparse'
require 'yaml'

require 'papertrail/cli'
require 'papertrail/connection'

module Papertrail
  class CliAddGroup<Cli
    def run
      # Let it slide if we have invalid JSON
      if JSON.respond_to?(:default_options)
        JSON.default_options[:check_utf8] = false
      end

      options = {
        :configfile => nil,
      }

      if configfile = find_configfile
        configfile_options = load_configfile(configfile)
        options.merge!(configfile_options)
      end

      OptionParser.new do |opts|
        opts.banner = "papertrail-add-group"

        opts.on("-h", "--help", "Show usage") do |v|
          puts opts
          exit
        end
        opts.on("-c", "--configfile PATH", "Path to config (~/.papertrail.yml)") do |v|
          options[:configfile] = File.expand_path(v)
        end
        opts.on("-g", "--group SYSTEM", "Name of group to add") do |v|
          options[:group] = v
        end
        opts.on("-w", "--system-wildcard WILDCARD", "Wildcard for system match") do |v|
          options[:wildcard] = v
        end

        opts.separator usage
      end.parse!

      if options[:configfile]
        configfile_options = load_configfile(options[:configfile])
        options.merge!(configfile_options)
      end

      raise OptionParser::MissingArgument if options[:group].nil?

      connection = Papertrail::Connection.new(options)

      # Bail if group already exists
      if connection.show_group(options[:group])
        exit 0
      end

      if connection.create_group(options[:group], options[:wildcard])
        exit 0
      end

      exit 1
    end

    def usage
      <<-EOF

  Usage: 
    papertrail-add-group [-g group] [-w system-wildcard] [-c papertrail.yml] 

  Example:
    papertrail-add-group -g mygroup -w mygroup-systems*

  EOF
    end
  end
end
