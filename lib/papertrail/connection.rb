require 'forwardable'
require 'openssl'

require 'papertrail/http_client'
require 'papertrail/search_query'

module Papertrail
  class Connection
    extend Forwardable

    attr_reader :connection

    def_delegators :@connection, :get, :put, :post, :delete

    def initialize(options)
      ssl_options = {
        :verify => options.fetch(:verify_ssl) { OpenSSL::SSL::VERIFY_PEER }
      }

      unless (options[:username] && options[:password]) || options[:token]
        raise ArgumentError, "Must provide a username and password or a token"
      end

      # Make Ubuntu OpenSSL work
      #
      # From: https://bugs.launchpad.net/ubuntu/+source/openssl/+bug/396818
      # "[OpenSSL] does not presume to select a set of CAs by default."
      if File.file?('/etc/ssl/certs/ca-certificates.crt')
        ssl_options[:ca_file] = '/etc/ssl/certs/ca-certificates.crt'
      end

      @connection = Papertrail::HttpClient.new(ssl_options).tap do |conn|
        if options[:username] && options[:password]
          conn.basic_auth(options[:username], options[:password])
        else
          conn.token_auth(options[:token])
        end
      end
    end

    def find_id_for_source(name)
      response = @connection.get('systems.json')

      find_id_for_item(response.body, name)
    end

    def find_id_for_group(name)
      response = @connection.get('groups.json')
      find_id_for_item(response.body, name)
    end

    def find_search(name, group_id = nil)
      response = @connection.get('searches.json')

      candidates = find_items_by_name(response.body, name)
      return nil if candidates.empty?

      candidates.each do |item|
        if !group_id || group_id == item['group_id']
          return item
        end
      end

      return candidates.first
    end

    def find_items_by_name(items, name_wanted)
      results = []

      items.each do |item|
        results << item if item['name'] == name_wanted
      end

      items.each do |item|
        results << item if item['name'] =~ /#{Regexp.escape(name_wanted)}/i
      end

      results
    end

    def find_item_by_name(items, name_wanted)
      find_items_by_name(items, name_wanted).first
    end

    def find_id_for_item(items, name_wanted)
      item = find_item_by_name(items, name_wanted)
      if item
        return item['id']
      end

      return nil
    end

    def create_group(name, system_wildcard = nil)
      group = { :group => { :name => name } }
      if system_wildcard
        group[:group][:system_wildcard] = system_wildcard
      end
      @connection.post("groups.json", group)
    end

    def show_group(name)
      if id = find_id_for_group(name)
        @connection.get("groups/#{id}.json").body
      end
    end

    def show_source(name)
      if id = find_id_for_source(name)
        @connection.get("systems/#{id}.json").body
      end
    end

    def join_group(source_name, group_name)
      source_id = find_id_for_source(source_name)
      group_id = find_id_for_group(group_name)
      if source_id && group_id
        @connection.post("systems/#{source_id}/join.json", :group_id => group_id)
      end
    end

    def leave_group(source_name, group_name)
      source_id = find_id_for_source(source_name)
      group_id = find_id_for_group(group_name)
      if source_id && group_id
        @connection.post("systems/#{source_id}/leave.json", :group_id => group_id)
      end
    end

    def register_source(name, *args)
      options = args.last.is_a?(Hash) ? args.pop.dup : {}

      if ip_address = args.shift
        options[:ip_address] = ip_address
      end

      if hostname = args.shift
        options[:hostname] = hostname
      end

      request = {
        :system => {
          :name => name
        }
      }

      if options[:ip_address]
        request[:system][:ip_address] = options[:ip_address]
      end

      if options[:hostname]
        request[:system][:hostname] = options[:hostname]
      end

      if options[:destination_port]
        request[:destination_port] = options[:destination_port]
      end

      @connection.post("systems.json", request)
    end

    def unregister_source(name)
      if source_id = find_id_for_source(name)
        @connection.delete("systems/#{source_id}.json")
      end
    end

    def each_event(query_term = nil, options = {}, &block)
      # If there was no query but there were options, shuffle around
      # the parameters
      if query_term.is_a?(Hash)
        options, query_term = query_term, nil
      end

      # Remove all of the options that shouldn't be in each query
      options  = { :tail => false }.merge(options)
      min_id   = options.delete(:min_id)
      max_id   = options.delete(:max_id)
      min_time = options.delete(:min_time)
      max_time = options.delete(:max_time)

      # Figure out where to start querying
      if min_id
        search = search_query(query_term, options.merge(:min_id => min_id))
      elsif min_time
        search = search_query(query_term, options.merge(:min_time => min_time.to_i))
      else
        raise ArgumentError, "Either :min_id or :min_time must be specified"
      end

      # Start processing events
      loop do
        search_results = search.results_page
        search_results.events.each do |event|
          # If we've found an event beyond what we were looking for, we're done
          break if max_time && event.received_at > max_time
          break if max_id && event.id > max_id

          block.call(event)
        end

        # If we've found the end of what we're looking for, we're done
        break if max_time && search_results.max_time_at > max_time
        break if max_id && search_results.max_id > max_id

        # If we've reached the most current log message, we're done
        break if search_results.reached_end?
      end

      nil
    end

    private

    def search_query(query = nil, options = {})
      Papertrail::SearchQuery.new(self, query, options)
    end
  end
end
