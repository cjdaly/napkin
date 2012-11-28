
# require 'stuff'
# Stuff.get_foo


require 'open-uri'
require 'rss/2.0'

class Stuff

	NAPKIN_URL = "http://192.168.2.50:4567"
	NAPKIN_ID = "sketchy"

	def doit(channel)
		rss_text = read_rss(channel)
		puts rss_text
		rss = RSS::Parser.parse(rss_text, false)
		rss.items.each_with_index do |item, i|
			puts "#{i}"
			puts "  #{item.title}"
			puts "  #{item.link}"
			# puts "  #{item.guid.content}"
			puts ""
			ruby_text = read_ruby(channel, item.link)
			puts ruby_text
			ec = Stuff::EvalContext.new.init
			eval ruby_text, ec.binding
		end
	end
	
	def read_rss(channel)
		open(NAPKIN_URL + "/channels/#{channel}/rss.xml", :http_basic_authentication=>[NAPKIN_ID, NAPKIN_ID]) do |rss_file|
			rss_text = rss_file.read
			return rss_text
		end
	end

	def read_ruby(channel, item_link)
		open(NAPKIN_URL + "/channels/#{channel}/" + item_link, :http_basic_authentication=>[NAPKIN_ID, NAPKIN_ID]) do |ruby_file|
			ruby_text = ruby_file.read
			return ruby_text
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

