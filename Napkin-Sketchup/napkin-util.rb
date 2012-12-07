require 'open-uri'
require 'rss/2.0'

def ntest(model="test1")
	napkin_util = NapkinUtil.new
	napkin_util.eval_model(model)
end

class NapkinUtil

	NAPKIN_URL = "http://192.168.2.50:4567"
	TEST_RSS_ROOT = NAPKIN_URL + "/sketchup/models/"

	NAPKIN_ID = "sketchy"

	SKETCHUP_DATA = { 'test' => 'hello' }

	def eval_model(model)
		rss_text = get_sketchup_text(model + "/rss.xml")
		# puts rss_text
		rss = RSS::Parser.parse(rss_text, false)
		rss.items.each_with_index do |item, i|
			puts "#{i} : #{item.title}"
			# puts "title    :  #{item.title}"
			# puts "link     :  #{item.link}"
			itemCategory = item.category.content
			# puts "category :  #{itemCategory}"
			# puts "  #{item.guid.content}"
			if (itemCategory == "ruby") then
				ruby_text = get_sketchup_text(model + "/" + item.link)
				# puts ruby_text
				ec = NapkinUtil::EvalContext.new.init
				eval ruby_text, ec.binding
				# sleep 0.2
			elsif (itemCategory == "rss") then
				subChannel = model + "/" + item.link
				eval_model(subChannel)
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

		def get_data(key)
			value = SKETCHUP_DATA[key]
			puts ("get_data: #{key} = #{value}")
			return value
		end

		def set_data(key, value)
			SKETCHUP_DATA[key] = value
		end
	end

end


