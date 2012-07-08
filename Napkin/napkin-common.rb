require 'napkin-util'

module NapkinCommon
  FEED_PROPS = PropertyMapper.new(['name','url','refresh_enabled','refresh_in_minutes'])

  FILE_META_PROPS = PropertyMapper.new(['etag', 'last-modified', 'date', 'expires'])
  CHANNEL_PROPS = PropertyMapper.new(['title', 'link', 'description', 'pubDate', 'lastBuildDate'])
  ITEM_PROPS = PropertyMapper.new(['title','link', 'description','guid','pubDate'])
end