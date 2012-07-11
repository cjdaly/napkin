code_dir = File.expand_path("../../Napkin-Data/open-uri-cache")
puts "code_dir: #{code_dir}"

def git_config(name, value)
  result_text = `git config --global #{name} "#{value}"`
  result_status = $?
  puts "CONFIG: #{name}=#{value} -> #{result_status}\n#{result_text}"
end

def git_command(command, code_dir, git_dir=code_dir + "/.git")
  result_text = `git --git-dir=#{git_dir} --work-tree=#{code_dir} #{command}`
  result_status = $?
  puts "COMMAND: #{command} -> #{result_status}\n#{result_text}"
end

git_config("user.name", "Dude")
git_config("user.email", "dude@example.com")
git_command("init",code_dir)

git_command("status -s",code_dir)
git_command("add .",code_dir)
git_command("commit -m \"...\"",code_dir)
git_command("status -s",code_dir)
git_command("tag -a myTag -m \"...\"",code_dir)
