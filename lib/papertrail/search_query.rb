require 'papertrail/search_result'

module Papertrail
  class SearchQuery
    def self.api_url
      '/api/v1/events/search.json'
    end

    def self.initial_search_limit
      100
    end

    def self.subsequent_search_limit
      1000
    end

    def initialize(connection)
      @connection = connection
    end

    attr_reader :max_id, :subsequent_request

    def search_results(query = nil, options = {})
      params = options.dup
      params[:q] = query if query
      params[:min_id] = max_id if max_id
      params[:limit] ||= default_request_limit

      response = @connection.get(self.class.api_url, params)
      @max_id = response.body['max_id']
      Papertrail::SearchResult.new(response.body)
    end

    def default_request_limit
      if subsequent_request
        self.class.subsequent_search_limit
      else
        @subsequent_request = true
        self.class.initial_search_limit
      end
    end
  end
end
