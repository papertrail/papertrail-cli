require 'papertrail/search_result'

module Papertrail
  class SearchQuery
    attr_reader :max_time

    def initialize(connection, query = nil, options = {})
      @connection = connection
      @query      = query
      @options    = options

      @min_time   = options[:min_time]
      @max_time   = options[:max_time]
    end
    
    def search
      response = @connection.get('/api/v1/events/search.json') do |r|
        r.params = @options.dup

        r.params[:q]      = @query  if @query
        r.params[:min_time] = @min_time if @min_time
        if @max_id
          r.params[:min_id] = @max_id 
        elsif @max_time
          r.params[:max_time] = @max_time
        end
      end

      @max_id = response.body['max_id']
      @max_time = response.body['max_time']
      Papertrail::SearchResult.new(response.body)
    end
  end
end
