require "test_helpers"

class AuthFormTest < Minitest::Test
	include Rack::Test::Methods
	include TestHelpers

	def setup
		u = User.new(valid_credentials)
		User.db[:users][u.username] = u

		app :bare do |app|
			
			app.plugin :auth, :form, redirect: '/login', cookie: {secret:'foo'}
			
			app.route do |r|
				r.post('login') { sign_in ? 'ok' : nil }
				r.get('login') { 'LOGIN FORM' }
				r.post('logout') { sign_out }
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
	
	def test_private_refuse_redirect
		response = request.get('/private')
		assert_equal 302, response.status
		assert_equal "/login", response.headers['LOCATION']
	end
	
	def test_private_accepted
		cookie = form_login.headers['Set-Cookie']
		response = request.get('/private')
		assert_equal 200, request.get('/private', {'HTTP_COOKIE' => cookie}).status
	end
	
	def test_private_error
		cookie = form_login(invalid_credentials).headers['Set-Cookie']
		assert_equal 302, request.get('/private', {'HTTP_COOKIE' => cookie}).status
	end		

end

class User < TestHelpers::User ; end

