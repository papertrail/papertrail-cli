require 'faraday'
require 'openssl'
require 'faraday_stack'

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
        builder.use     FaradayStack::ResponseJSON
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

      response.body.each do |source|
        return source['id'] if source['name'] =~ /#{Regexp.escape(name)}/i
      end

      return nil
    end

    def find_id_for_group(name)
      response = @connection.get('/api/v1/groups.json')

      response.body.each do |group|
        return group['id'] if group['name'] =~ /#{Regexp.escape(name)}/i
      end

      return nil
    end

    def query(query = nil, options = {})
      Papertrail::SearchQuery.new(self, query, options)
    end
  end
end