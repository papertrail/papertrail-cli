require 'papertrail/search_result'

module Papertrail
  class SearchQuery
    def self.api_url
      '/api/v1/events/search.json'
    end

    attr_reader :max_id

    def search_results(connection, query = nil, options = {})
      params = options.dup
      params[:q] = query if query
      params[:min_id] = max_id if max_id

      response = connection.get(self.class.api_url, params)
      @max_id = response.body['max_id']
      Papertrail::SearchResult.new(response.body)
    end
  end
end
