require 'papertrail/search_result'

# SearchQuery manages pagination.
# Once initialized, call `results_page` for a page of results
# call it again to get the next results, and again, and again
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

    def initialize(connection, query = nil, options = {})
      @connection = connection
      @query      = query
      @options    = options
    end

    attr_accessor :max_id, :subsequent_request

    def results_page
      params = @options.dup
      params[:q] = @query if @query
      params[:min_id] = @max_id if @max_id
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
