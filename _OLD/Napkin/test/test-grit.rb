require 'rubygems'
require 'grit'

# repo = Grit::Repo.new("../../Napkin-Data/open-uri-cache/.git")
repo = Grit::Repo.init_bare("../../Napkin-Data/open-uri-cache/.git")

puts "created repo #{repo}"

status = repo.commit_all("test...")
puts "commit status: #{status}"