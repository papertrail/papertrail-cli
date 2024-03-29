module Papertrail
  module CliHelpers
    def find_configfile
      if File.exist?(path = File.expand_path('.papertrail.yml'))
        return path
      end
      if File.exist?(path = File.expand_path('~/.papertrail.yml'))
        return path
      end
    rescue ArgumentError
    end

    def load_configfile(file_path)
      symbolize_keys(YAML.load_file(file_path))
    end

    def symbolize_keys(hash)
      new_hash = {}
      hash.each do |(key, value)|
        new_hash[(key.to_sym rescue key) || key] = value
      end

      new_hash
    end

    def set_min_max_time!(opts, q_opts)
      q_opts[:min_time] = parse_time(opts[:min_time]).to_i if opts[:min_time]
      q_opts[:max_time] = parse_time(opts[:max_time]).to_i if opts[:max_time]
    end

    def parse_time(tstring)
      Chronic.parse(tstring) ||
        raise(ArgumentError, "Could not parse time string '#{tstring}'")
    end

    def output_http_error(e)
      if e.response && e.response.body
        puts "Error: #{e.response.body}\n\n"
      end

      puts e
    end
  end
end
