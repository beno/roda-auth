require "test_helpers"

class AuthTokenTest < Minitest::Test
	include Rack::Test::Methods
	include TestHelpers

	
	def setup
		@u = User.new(valid_credentials)
		User.db[:users][@u.username] = @u
		User.db[:tokens]['1234token'] = @u

		app :bare do |app|
			
			app.plugin :auth, :token
			
			app.route do |r|
				r.on 'public' do
					'public'
				end
				r.post('session') do |args|
					 sign_in
					{'token' => current_user.token}.to_json 
				end
				authenticate!
				r.is('session', method: :delete) { sign_out }
				r.on 'private' do
					"private #{current_user.token}"
				end
			end
		end
	end
	
	def test_unprotected_access
		response = request.get '/public'
		assert_equal "public", response.body
		assert_equal 200, response.status
	end
	
	
	def test_protected_error
		response = request.get '/private'
		assert_equal 401, response.status
	end
	
	def test_login_body
		response = json_login
		assert_equal 200, response.status
	end
	
	def test_login_body_invalid
		response = json_login(invalid_credentials)
		assert_equal 401, response.status
	end
	
	def test_token_response
		session = JSON.parse(json_login.body)
		assert_equal @u.token, session['token']
	end
	
	def test_token_access
		session = JSON.parse(json_login.body)
		response = request.get('/private', {'HTTP_AUTHORIZATION' => "Auth #{session['token']}"})
		assert_equal 200, response.status
		assert_equal "private #{session['token']}", response.body
	end
	
	def test_logout
		session = JSON.parse(json_login.body)
		response = request.delete('/session', {'HTTP_AUTHORIZATION' => "Auth #{session['token']}"})
		assert_equal 204, response.status
	end
			
	private
	
	def json_login(cred = valid_credentials)
		request.post('/session', params: cred.to_json)
	end

	
end


class User < TestHelpers::User ; end

