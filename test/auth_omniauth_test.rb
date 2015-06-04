require "test_helpers"
require "omniauth-twitter"
require "omniauth-facebook"

class OmniauthTest < Minitest::Test
	include Rack::Test::Methods
	include TestHelpers


	def setup
		u = User.new(valid_credentials)
		User.db[:users][u.username] = u

		app :bare do |app|

			app.plugin :auth, :token, omniauth: [:twitter, :facebook]
			route do |r|
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
		response = request.get('/public')
		assert_equal "public", response.body
		assert_equal 200, response.status
	end

	def test_protected_error
		assert_equal 401, request.get('/private').status
	end

	def test_twitter_redirect
		response = request.get('/auth/twitter')
		assert_equal 302, response.status
		assert_equal "api.twitter.com", URI(response.headers['LOCATION']).host
	end

	def test_facebook_redirect
		response = request.get('/auth/facebook')
		assert_equal 302, response.status
		assert_equal "www.facebook.com", URI(response.headers['LOCATION']).host
	end


	# def test_private_accepted
	# 	post('/logout')
	# 	cookie = login
	# 	assert_equal 200, status('/private', {'HTTP_COOKIE' => cookie})
	# end
	#
	# def test_private_error
	# 	req('/logout')
	# 	cookie = login(invalid_credentials)
	# 	assert_equal 302, status('/private', {'HTTP_COOKIE' => cookie})
	# end

end


class User < TestHelpers::User ; end
