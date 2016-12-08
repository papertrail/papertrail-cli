require 'time'

module Papertrail
  class Event
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def received_at
      @received_at ||= Time.parse(data['received_at'])
    end

    def to_s
      "#{received_at.strftime('%b %d %X')} #{data['hostname']} #{data['program']}: #{data['message']}"
    end
  end
end