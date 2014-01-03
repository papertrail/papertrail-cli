require 'papertrail/event'

module Papertrail
  class SearchResult
    attr_reader :data, :events

    def initialize(data)
      @data = data

      @events = @data['events'].collect do |event|
        Papertrail::Event.new(event)
      end
    end

    def reached_end?
      @data['reached_end']
    end

    def max_time_at
      @max_time_at ||= Time.parse(@data['max_time_at'])
    end

    def max_id
      @data['max_id']
    end

    def min_id
      @data['min_id']
    end
  end
end