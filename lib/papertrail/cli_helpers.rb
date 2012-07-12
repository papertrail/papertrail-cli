module Papertrail
  module CliHelpers
    def find_configfile
      if File.exists?(path = File.expand_path('.papertrail.yml'))
        return path
      end
      if File.exists?(path = File.expand_path('~/.papertrail.yml'))
        return path
      end
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
  end
end
