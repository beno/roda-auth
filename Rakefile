require 'rake/testtask'

Rake::TestTask.new do |t|
	t.libs << "test"
	t.pattern = "test/*_test.rb"
end

desc 'individual test'
task :one, [:file] do |_, f|
	Rake::TestTask.new do |t|
		t.libs << "test"
		t.test_files = [f[:file]]
	end
end
