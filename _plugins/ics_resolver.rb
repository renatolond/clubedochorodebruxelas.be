# frozen_string_literal: true

require "icalendar"
require "net/http"

# This class resolves any ICS related to the clube. That means downloading the latest ICS from mobilizon, but also creating the ICS for the workshops
module IcsResolver
  DEFAULTS = {
    "staging_path" => "_ics_staging"
  }.freeze

  EVENT_FILENAME = "events.ics"
  WORKSHOP_EVENTS_FILENAME = "workshops.ics"

  class << self
    # @param jekyll_config [Jekyll::Configuration]
    # @return [String]
    def config_staging_path(jekyll_config)
      config = jekyll_config["ics_resolver"] || [{}]
      config[0]["staging_path"] || DEFAULTS["staging_path"]
    end

    # @param site [Jekyll::Site]
    # @return [void]
    def create_calendar_from_workshop_dates(site)
      cal = Icalendar::Calendar.new

      cal.timezone do |t|
        t.tzid = "Europe/Brussels"

        t.daylight do |d|
          d.tzoffsetfrom = "+0100"
          d.tzoffsetto   = "+0200"
          d.tzname       = "CEST"
          d.dtstart      = "19700329T020000"
          d.rrule        = "FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU"
        end

        t.standard do |s|
          s.tzoffsetfrom = "+0200"
          s.tzoffsetto   = "+0100"
          s.tzname       = "CET"
          s.dtstart      = "19701025T030000"
          s.rrule        = "FREQ=YEARLY;BYMONTH=01;BYDAY=1SU"
        end
      end

      source = site.source
      staging_path = config_staging_path(site.config)
      if site.config["active_lang"] == site.config["default_lang"]
        staging_destination = File.join(source, staging_path)
        url = "#{site.config["url"]}#{LinkForCurrentLanguage.link(site, "/ateliers")}"
      else
        staging_destination = File.join(source, staging_path, site.config["active_lang"])
        url = "#{site.config["url"]}/#{site.config["active_lang"]}#{LinkForCurrentLanguage.link(site, "/ateliers")}"
      end
      beginner_start_time = site.data.dig("workshop_dates", "beginner_class", "start_time")
      beginner_end_time = site.data.dig("workshop_dates", "beginner_class", "end_time")
      advanced_start_time = site.data.dig("workshop_dates", "advanced_class", "start_time")
      advanced_end_time = site.data.dig("workshop_dates", "advanced_class", "end_time")
      idx = 1
      site.data.dig("workshop_dates", "dates").each do |date|
        cal.event do |e|
          e.summary = "#{LocalizeTag.translate(site, "atelier_niveau_1")} ##{idx}"
          e.dtstart = DateTime.parse("#{date} #{beginner_start_time}")
          e.dtend = DateTime.parse("#{date} #{beginner_end_time}")
          e.url = url
        end
        cal.event do |e|
          e.summary = "#{LocalizeTag.translate(site, "atelier_niveau_2")} ##{idx}"
          e.dtstart = DateTime.parse("#{date} #{advanced_start_time}")
          e.dtend = DateTime.parse("#{date} #{advanced_end_time}")
          e.url = url
        end
        idx += 1
      end
      FileUtils.mkpath(staging_destination) unless File.directory?(staging_destination)
      generated_staging_path = File.join(staging_destination, WORKSHOP_EVENTS_FILENAME)
      File.write(generated_staging_path, cal.to_ical)
      site.static_files << Jekyll::StaticFile.new(site, staging_destination, "/", WORKSHOP_EVENTS_FILENAME)
    end

    # @param site [Jekyll::Site]
    # @return [void]
    def download_mobilizon_ics(site)
      source = site.source
      staging_path = config_staging_path(site.config)
      staging_destination = File.join(source, staging_path)
      FileUtils.mkpath(staging_destination) unless File.directory?(staging_destination)

      uri = URI("#{site.config["mobilizon_user_page"]}/feed/ics")
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Get.new uri
        response = http.request request # Net::HTTPResponse object
        if response.code == "200" && response.header["content-type"].start_with?("text/calendar")
          source = site.source
          staging_destination = File.join(source, staging_path)
          generated_staging_path = File.join(staging_destination, EVENT_FILENAME)
          File.write(generated_staging_path, response.body)
        end
      end
    end

    # @param site [Jekyll::Site]
    # @return [void]
    def add_files_to_static_files(site)
      source = site.source
      staging_path = config_staging_path(site.config)
      staging_destination = File.join(source, staging_path)
      site.static_files << Jekyll::StaticFile.new(site, staging_destination, "/", EVENT_FILENAME)
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  IcsResolver.create_calendar_from_workshop_dates(site)

  IcsResolver.add_files_to_static_files(site)
end

Jekyll::Hooks.register :site, :after_init do |site|
  IcsResolver.download_mobilizon_ics(site)
end
