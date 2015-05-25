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
		assert_equal 200, status('/public')
	end
	
	def test_private_refuse_redirect
		r = req('/private')
		assert_equal 302, r[0]
		assert_equal "/login", r[1]['LOCATION']
	end
	
	def test_private_accepted
		post('/logout')
		cookie = login
		assert_equal 200, status('/private', {'HTTP_COOKIE' => cookie})
	end
	
	def test_private_error
		req('/logout')
		cookie = login(invalid_credentials)
		assert_equal 302, status('/private', {'HTTP_COOKIE' => cookie})
	end


	
	private
		
	def login(cred = valid_credentials)
		r = req('/login', {'REQUEST_METHOD' => 'POST', 'rack.input' => save_args(cred)})
		r[0] == 200 && r[1]["Set-Cookie"]
	end
	

		
end


class User < TestHelpers::User ; end

