
# require 'stuff'
# Stuff.get_foo


require 'open-uri'
require 'rss/2.0'

class Stuff

	def doit(channel)
		rss_text = read_rss(channel)
		puts rss_text
		rss = RSS::Parser.parse(rss_text, false)
		rss.items.each_with_index do |item, i|
			puts "#{i}"
			puts "  #{item.title}"
			puts "  #{item.link}"
			puts "  #{item.guid.content}"
			puts ""
			ruby_text = read_ruby(item.link)
			puts ruby_text
			ec = Stuff::EvalContext.new.init
			eval ruby_text, ec.binding
		end
	end
	
	def read_rss(channel)
		open("http://localhost:4567/channels/#{channel}/rss.xml") do |rss_file|
			rss_text = rss_file.read
			return rss_text
		end
	end

	def read_ruby(item_link)
		open(item_link) do |ruby_file|
			ruby_text = ruby_file.read
			return ruby_text
		end
	end

	class EvalContext
		def init
			Proc.new {}
		end

		def helper
			puts "in helper"
		end
	end

end

