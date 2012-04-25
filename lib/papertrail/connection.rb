require 'faraday'
require 'openssl'
require 'faraday_middleware'
require 'yajl/json_gem'

require 'papertrail/search_query'

module Papertrail
  class Connection
    extend Forwardable

    attr_reader :connection

    def_delegators :@connection, :get, :put, :post

    def initialize(options)
      ssl_options = { :verify => OpenSSL::SSL::VERIFY_PEER }

      # Make Ubuntu OpenSSL work
      #
      # From: https://bugs.launchpad.net/ubuntu/+source/openssl/+bug/396818
      # "[OpenSSL] does not presume to select a set of CAs by default."
      if File.file?('/etc/ssl/certs/ca-certificates.crt')
        ssl_options[:ca_file] = '/etc/ssl/certs/ca-certificates.crt'
      end

      @connection = Faraday::Connection.new(:url => 'https://papertrailapp.com', :ssl => ssl_options) do |builder|
        builder.adapter Faraday.default_adapter
        builder.use Faraday::Response::RaiseError
        builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
      end.tap do |conn|
        if options[:username] && options[:password]
          conn.basic_auth(options[:username], options[:password])
        else
          conn.headers['X-Papertrail-Token'] = options[:token]
        end
      end
    end

    def find_id_for_source(name)
      response = @connection.get('/api/v1/systems.json')

      find_id_for_item(response.body, name)
    end

    def find_id_for_group(name)
      response = @connection.get('/api/v1/groups.json')

      find_id_for_item(response.body, name)
    end

    def find_id_for_item(items, name_wanted)
      items.each do |item|
        return item['id'] if item['name'] == name_wanted
      end

      items.each do |item|
        return item['id'] if item['name'] =~ /#{Regexp.escape(name_wanted)}/i
      end
    end

    def query(query = nil, options = {})
      Papertrail::SearchQuery.new(self, query, options)
    end
  end
end