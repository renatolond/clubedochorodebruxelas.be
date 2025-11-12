# frozen_string_literal: true

require "icalendar"

module Jekyll
  module ICSReader
    def read_calendar(input)
      calendar_file = File.open(input)

      events = Icalendar::Event.parse(calendar_file)

      ret = []

      events.each do |event|
        next if event.dtstart <= DateTime.now

        ret << {
          "summary" => event.summary,
          "dtstart" => event.dtstart,
          "dtend" => event.dtend,
          "url" => event.url.to_s
        }
      end

      ret
    rescue
      # Handle errors
      Jekyll.logger.error "Calendar Reader:", "An error occurred!"

      {}
    end
  end
end

Liquid::Template.register_filter(Jekyll::ICSReader)
