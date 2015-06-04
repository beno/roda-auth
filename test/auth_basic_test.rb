require "test_helpers"

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
		assert_equal 200, request.get('/public').status
	end
	
	def test_private_refused
		assert_equal 401, request.get('/private').status
		assert_equal "Basic realm=\"/private\"", request.get('/private').headers['WWW-AUTHENTICATE']
	end
	
	def test_private_accepted
		assert_equal 200, request.get('/private', {"HTTP_AUTHORIZATION" => "Basic #{http_auth(valid_credentials)}"}).status
	end
		
end


class User < TestHelpers::User ; end

