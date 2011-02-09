module Papertrail
  class SearchClient
    attr_accessor :username, :password, :conn
  
    def initialize(username, password)
      @username = username
      @password = password
    
      @conn = Faraday::Connection.new(:url => 'https://papertrailapp.com', :ssl => { :verify => true }) do |builder|
        builder.basic_auth(@username, @password)

        builder.adapter  :typhoeus
        builder.response :yajl
      end

      @max_id_seen = {}    
    end
    
    # search for all events or a specific query, defaulting to all events since
    # last result set (call with since=0 for all).
    def search(q = nil, since = nil)
      response = @conn.get('/api/v1/events/search.json') do |r|
        r.params = params_for_query(q, since)
      end

      if response.body
        @max_id_seen[q] = response.body['max_id']
        response.body['events']
      end
    end
    
    def params_for_query(q = nil, since = nil)
      params = {}
      params[:q] = q if q
      params[:min_id] = @max_id_seen[q] if @max_id_seen[q]
      params[:min_id] = since if since
      params
    end
    
    def self.format_events(events, &block)
      events.each do |event|
        yield "#{Time.parse(event['received_at']).strftime('%b %e %X')} #{event['hostname']} #{event['program']} #{event['message']}"
      end
    end
  end
end
