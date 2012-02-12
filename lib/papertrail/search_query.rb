require 'papertrail/search_result'

module Papertrail
  class SearchQuery
    def initialize(connection, query = nil, options = {})
      @connection = connection
      @query      = query
      @options    = options
    end

    def search
      response = @connection.get('/api/v1/events/search.json') do |r|
        r.params = @options.dup

        r.params[:q]      = @query  if @query
        r.params[:min_id] = @max_id if @max_id
      end

      @max_id = response.body['max_id']
      Papertrail::SearchResult.new(response.body)
    end
  end
end