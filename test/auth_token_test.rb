require "test_helpers"

class AuthTokenTest < Minitest::Test
	include Rack::Test::Methods
	include TestHelpers

	
	def setup
		u = User.new(valid_credentials)
		User.db[:users][u.username] = u

		app :bare do |app|
			
			app.plugin :auth, :token
			
			app.route do |r|
				r.on 'public' do
					'public'
				end
				r.post('session') { sign_in.to_json }
				authenticate!
				r.is('session', method: :delete) { sign_out }
				r.on 'private' do
					"private #{current_user.username}"
				end
			end
		end
	end
	
	def test_unprotected_access
		assert_equal "public", body('/public')
		assert_equal 200, status('/public')
	end
	
	
	def test_protected_error
		assert_equal 401, status('/private')
	end
	
	def test_login_body
		assert_equal 200, status('/session', {'REQUEST_METHOD' => 'POST', 'rack.input' => save_args(valid_credentials)})
	end
	
	def test_login_body_invalid
		assert_equal 401, status('/session', {'REQUEST_METHOD' => 'POST', 'rack.input' => save_args(invalid_credentials)})
	end
	
	def test_token_response
		json = body('/session', {'REQUEST_METHOD' => 'POST', 'rack.input' => save_args(valid_credentials)})
		args = JSON.parse(json)
		assert_equal valid_credentials[:username], args['username']
		assert args['token']
	end
	
	def test_token_access
		user_args = login
		assert_equal 200, status('/private', {"HTTP_AUTHORIZATION" => "Auth #{user_args['token']}"})
		assert_equal "private #{user_args['username']}", body('/private', {"HTTP_AUTHORIZATION" => "Auth #{user_args['token']}"})
	end
	
	def test_logout
		user_args = login
		assert_equal 204, status('/session', {'REQUEST_METHOD' => 'DELETE', "HTTP_AUTHORIZATION" => "Auth #{user_args['token']}"})
	end
	
	private
		
	def login
		body = body('/session', {'REQUEST_METHOD' => 'POST', 'rack.input' => save_args(valid_credentials)})
		JSON.parse(body)
	end
	
end


class User < TestHelpers::User ; end

