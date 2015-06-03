Gem::Specification.new do |s|
	s.name        = 'roda-auth'
	s.version     = '0.1.0'
	s.date        = '2014-12-21'
	s.summary     = "Roda authentication"
	s.description = "A Roda plugin for authentication with Warden"
	s.authors     = ["Michel Benevento"]
	s.email       = 'michelbenevento@yahoo.com'
	s.files       = ["lib/roda/auth.rb", "lib/roda/plugins/auth.rb"]
	s.homepage    = 'http://github.com/beno/roda-auth'
	s.license     = 'MIT'
	
	s.add_runtime_dependency 'roda', '~> 2'
	s.add_runtime_dependency 'warden', '~> 1.2'
	s.add_runtime_dependency 'bcrypt', '~> 3'
	s.add_runtime_dependency 'omniauth', '~> 1'
	s.add_runtime_dependency 'rack_csrf', '~> 2.5'

	s.add_development_dependency 'rake', '~> 10'
	s.add_development_dependency 'minitest', '~> 5.5'
	s.add_development_dependency 'rack-test', '~> 0.6'
	s.add_development_dependency 'omniauth-twitter'
	s.add_development_dependency 'omniauth-facebook'

end