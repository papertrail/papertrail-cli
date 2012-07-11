require 'addressable/uri'
require 'faraday'
require 'openssl'
require 'faraday_middleware'
require 'yajl/json_gem'

require 'papertrail/search_query'

module Papertrail
  class Connection
    extend Forwardable

    attr_reader :connection

    def_delegators :@connection, :get, :put, :post, :delete

    def initialize(options)
      @api_prefix = '/api/v1'
      @groups_api = "#{@api_prefix}/groups"
      @systems_api = "#{@api_prefix}/systems"

      ssl_options = {
        :verify => options.fetch(:verify_ssl) { OpenSSL::SSL::VERIFY_PEER }
      }

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
        builder.use Faraday::Request::UrlEncoded
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
      return nil
    end

    def create_group(name, system_wildcard = nil)
      group = { :group => { :name => name } }
      if (system_wildcard)
        group[:group][:system_wildcard] = system_wildcard
      end
      group_query = Addressable::URI.new
      group_query.query_values = group
      response = @connection.post("#{@groups_api}.json", group_query.query)
      return response.status == 200
    end

    def show_group(name)
      id = find_id_for_group(name)
      if (id)
        response = @connection.get("#{@groups_api}/#{id}.json")
        return response.body
      end
    end

    def show_source(name)
      id = find_id_for_source(name)
      if (id)
        response = @connection.get("#{@systems_api}/#{id}.json")
        return response.body
      end
    end

    def join_group(source_name, group_name)
      source_id = find_id_for_source(source_name)
      group_id = find_id_for_group(group_name)
      if (source_id && group_id)
        group_query = Addressable::URI.new
        group_query.query_values = { :group_id => group_id }
        response = @connection.post("#{@systems_api}/#{source_id}/join.json", group_query.query)
        return response.status == 200
      end
    end

    def register_source(name, ip_address)
      system_query = Addressable::URI.new
      system_query.query_values = { :system => { :name => name, :ip_address => ip_address } }
      response = @connection.post("#{@systems_api}.json", system_query.query)
      return response.status == 200
    end

    def unregister_source(name)
      source_id = find_id_for_source(name)
      if (source_id)
        response = @connection.delete("#{@systems_api}/#{source_id}.json")
        return response.status == 200
      end
    end

    def query(query = nil, options = {})
      Papertrail::SearchQuery.new(self, query, options)
    end
  end
end
