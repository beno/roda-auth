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
		assert_equal "public", body('/public')
		assert_equal 200, status('/public')
	end

	def test_protected_error
		assert_equal 401, status('/private')
	end

	def test_twitter_redirect
		status, headers = req('/auth/twitter', {'rack.input' => []})
		assert_equal 302, status
		assert_equal "api.twitter.com", URI(headers['LOCATION']).host
	end

	def test_facebook_redirect
		status, headers = req('/auth/facebook', {'rack.input' => ""})
		assert_equal 302, status
		assert_equal "www.facebook.com", URI(headers['LOCATION']).host
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
