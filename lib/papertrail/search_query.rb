require 'papertrail/search_result'

module Papertrail
  class SearchQuery
    def self.api_url
      '/api/v1/events/search.json'
    end

    def self.initial_search_limit
      100
    end

    attr_reader :max_id, :has_connected

    def search_results(connection, query = nil, options = {})
      params = options.dup
      params[:q] = query if query
      params[:min_id] = max_id if max_id
      params[:limit] ||= self.class.initial_search_limit unless has_connected

      response = connection.get(self.class.api_url, params)
      @max_id = response.body['max_id']
      @has_connected = true
      Papertrail::SearchResult.new(response.body)
    end
  end
end
