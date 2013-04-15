####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####
require 'rubygems'
require 'grit'

# repo = Grit::Repo.new("../../Napkin-Data/open-uri-cache/.git")
repo = Grit::Repo.init_bare("../../Napkin-Data/open-uri-cache/.git")

puts "created repo #{repo}"

status = repo.commit_all("test...")
puts "commit status: #{status}"