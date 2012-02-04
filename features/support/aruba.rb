require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 10
  @old_home = ENV['HOME']
  ENV['HOME'] = File.expand_path(dirs.first)
end

After do
  ENV['HOME'] = @old_home
end
