require "bundler"
Bundler.require

require "sinatra"
require "sinatra/flash"
require "sinatra/reloader" if Sinatra::Base.development?
require "icalendar/tzinfo"
require "parse-ruby-client"

Parse.init	:application_id => ENV["APP_KEY"],
			:api_key => ENV["API_KEY"]

# Monkey patch icalendar to allow for dtstamp
module Icalendar
	class Calendar
		optional_single_property :dtstamp, Icalendar::Values::DateTime
	end
end

def get_hh_parse_as_ical
	cal = Icalendar::Calendar.new
	cal.prodid = "-//Hackevents//cal.hackevents.co//EN"
	cal.dtstamp = Date.new

	query = Parse::Query.new("Hackathon")
	results = query.get

	results.each do |r|
		event_name = r["displayName"]
		event_url = r["url"]
		event_sdate = r["date"]
		event_edate = r["finishDate"]
		event_location = r["location"]
		event_city = r["locationCity"]


		event = Icalendar::Event.new
		event.summary = event_name
		event.description = "#{event_name} in #{event_city}. \npowered by Hackevents"
		event.location = event_location
		event.url = event_url
		event.url.ical_params = { "VALUE" => "URI" }
		event.dtstart = event_sdate
		event.dtend = event_edate

		cal.add_event(event) # if event_sdate.gsub(/\D+/i, "").to_i > 0
	end

	cal.to_ical
end


def set_headers
	response.headers['Content-Type'] = 'text/calendar'
	response.headers['Content-Type'] = 'text/plain' if Sinatra::Base.development?
	response['Access-Control-Allow-Origin'] = '*'
end

def create_feed
	set_headers

	get_hh_parse_as_ical
end

get '/' do
	create_feed
end
