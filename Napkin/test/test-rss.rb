
require 'rss/2.0'

puts "Hello"

rss = RSS::Rss.new("2.0")
ch = RSS::Rss::Channel.new
ch.title="test"
ch.description = "Feed description"
ch.link = "http://localhost:4567/channels/test"
rss.channel = ch

3.times do |n|
	item = RSS::Rss::Channel::Item.new
	item.title = "item#{n}"
	item.link = "http://localhost:4567/channels/test/item#{n}.rb"
	#item.description = "desc"
	#item.date=Time.now
	#item.guid = RSS::Rss::Channel::Item::Guid.new
	#item.guid.content = "guid" + n.to_s
	ch.items << item
end

puts rss.class
puts rss.channel.link
puts rss.to_s

puts "Goodbye"

