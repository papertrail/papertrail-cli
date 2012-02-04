require 'time'

module Papertrail
  class Event
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def to_s
      "#{Time.parse(data['received_at']).strftime('%b %e %X')} #{data['hostname']} #{data['program']}: #{data['message']}"
    end
  end
end