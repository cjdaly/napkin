#  http://forums.sketchucation.com/viewtopic.php?f=180&t=29412
#
#  file: '!loadpaths.rb'
#  for Win32
#
#  Version 3.0.1   -  Public Domain
#
#  Authored by  :  Dan Rathbun
#  Contributors :  Jim Foltz
#
begin
  #
  # TWEEKER variables 
  # 
  # may change 'ver' to a literal string
  if RUBY_VERSION < '1.9.0'
    ver=RUBY_VERSION.split('.')[0..1].join('.')
  else
    ver=RUBY_VERSION
  end
  #
  # 'pre' is the rubylib path prefix
  pre='C:/ruby'<<RUBY_VERSION.split('.').join<<'/lib/ruby'
  #
  plat=RUBY_PLATFORM
  # 
  # add the standard lib path 
  $LOAD_PATH << "#{pre}/#{ver}" 
  # add the standard platform sub lib path 
  $LOAD_PATH << "#{pre}/#{ver}/#{plat}"
  # 
  # optionally add paths to vendor_ruby libs 
  # only apply if there are things installed there 
  #$LOAD_PATH << "#{pre}/vendor_ruby/#{ver}" 
  #$LOAD_PATH << "#{pre}/vendor_ruby/#{ver}/#{plat}" 
  #
  # optionally add paths to site_ruby libs 
  # only apply if there are things installed there 
  #$LOAD_PATH << "#{pre}/site_ruby/#{ver}" 
  #$LOAD_PATH << "#{pre}/site_ruby/#{ver}/#{plat}" 
  #
  #  C:\projects\Neo4j-Sketchup\play\sketchup
  $LOAD_PATH << "C:/projects/Neo4j-Sketchup/play/sketchup"
  # 
  $LOAD_PATH.uniq!
  #
  # print LOAD PATHS to console
  # (May not print during Sketchup startup!)
  Sketchup.send_action('showRubyPanel:')
  UI.start_timer(1,false) {
    puts "\nLOAD PATHS:\n" 
    $LOAD_PATH.each {|x| puts "#{x}\n"} 
    puts "\n\n"
  }
  # 
end
# cleanup
ver=nil
pre=nil
plat=nil
GC.start
#
# end of '!loadpaths.rb'

