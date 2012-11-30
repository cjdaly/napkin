
# require 'stuff'
# Stuff.get_foo


require 'open-uri'
require 'rss/2.0'

class Stuff

	NAPKIN_URL = "http://192.168.2.50:4567"
	TEST_RSS_ROOT = NAPKIN_URL + "/channels/"

	NAPKIN_ID = "sketchy"

	def doit(channel)
		rss_text = get_sketchup_text(channel + "/rss.xml")
		puts rss_text
		rss = RSS::Parser.parse(rss_text, false)
		rss.items.each_with_index do |item, i|
			puts "#{i}"
			puts "title    :  #{item.title}"
			puts "link     :  #{item.link}"
			itemCategory = item.category.content
			puts "category :  #{itemCategory}"
			# puts "  #{item.guid.content}"
			puts ""
			if (itemCategory == "ruby") then
				ruby_text = get_sketchup_text(channel + "/" + item.link)
				puts ruby_text
				ec = Stuff::EvalContext.new.init
				eval ruby_text, ec.binding
			elsif (itemCategory == "rss") then
				subChannel = channel + "/" + item.link
				doit(subChannel)
			end
		end
	end
	
	def get_sketchup_text(path, napkin_sketchup_url = TEST_RSS_ROOT)
		url = napkin_sketchup_url + path
		open(url, :http_basic_authentication=>[NAPKIN_ID, NAPKIN_ID]) do |get_file|
			sketchup_text = get_file.read
			return sketchup_text
		end
	end

	class EvalContext
		def init
			Proc.new {}
		end

		def helper
			puts "in helper as #{NAPKIN_ID}"
		end
	end

end

