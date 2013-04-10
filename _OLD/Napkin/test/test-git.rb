code_dir = File.expand_path("../../Napkin-Data/open-uri-cache")
puts "code_dir: #{code_dir}"

def git_command(command, code_dir, git_dir=code_dir + "/.git")
  command_text = "git --git-dir=#{git_dir} --work-tree=#{code_dir} #{command}"
  result_text = `#{command_text}`
  result_status = $?
  puts "COMMAND: #{command_text}\n  -> #{result_status}\n#{result_text}"
end

git_command("config --file #{code_dir}/.git/config user.name Sled", code_dir)
git_command("config --file #{code_dir}/.git/config user.email sled@example.com", code_dir)

#git_command("init",code_dir)
#git_command("status -s",code_dir)
#git_command("add .",code_dir)
#git_command("commit -m \"...\"",code_dir)
#git_command("status -s",code_dir)
#git_command("tag -a myTag -m \"...\"",code_dir)
