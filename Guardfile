guard :minitest do
  watch(%r{^test/(.*)_test.rb$})
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[2]}_test.rb" }
  watch(%r{^test/test_helper\.rb$})      { 'test' }
end