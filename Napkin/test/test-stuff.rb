require 'yaml'

require 'rubygems'
require 'rest-client'

x = {'feed_name' =>"Fred", :feed_url => "http://fred.com", :state => "go", :refresh_rate => "15"}

puts x

x_yaml = YAML.dump(x)
puts x_yaml

module Test
  PROPS = ['feed_name','feed_url','poll_state','refresh_rate']
    
  def Test.yaml_to_hash(yaml_text)
    yaml = YAML.load(yaml_text)
    out = {}
    PROPS.each do |key|
      val = yaml[key]
      if (!val.nil?) then
        out[key] = val
      end
    end
    return out
  end
  
end

puts "Hello!"
puts Test.yaml_to_hash(x_yaml)
