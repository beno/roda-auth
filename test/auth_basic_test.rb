require "test_helpers"
require 'json'
require 'roda/auth'

class AuthBasicTest < Minitest::Test
	include Rack::Test::Methods
	include TestHelpers

	
	def setup
		u = User.new(valid_credentials)
		User.db[:users][u.username] = u

		app :bare do |app|
			
			app.plugin :auth
			
			app.route do |r|
				r.on 'public' do
					'public'
				end
				authenticate!
				r.on 'private' do
					'private'
				end
			end
		end
	end
	
	def test_public
		assert_equal 200, status('/public')
	end

	def test_private_refused
		assert_equal 401, status('/private')
		assert_equal "Basic realm=\"/private\"", header('WWW-AUTHENTICATE', '/private')
	end
	
	def test_private_accepted
		assert_equal 200, status('/private', {"HTTP_AUTHORIZATION" => "Basic #{http_auth(valid_credentials)}"})
	end
		
end


class User < TestHelpers::User ; end

