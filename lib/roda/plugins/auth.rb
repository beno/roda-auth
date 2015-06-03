require 'base64'
require 'bcrypt'
require 'json'
require 'warden'
require 'roda'
require 'omniauth'

class Roda

	module RodaPlugins

		module Auth

			def self.load_dependencies(app, *args, &block)
				app.plugin :drop_body
				app.plugin :environments
				Warden::Strategies.add(:token, Strategies::Token)
				Warden::Strategies.add(:password, Strategies::Password)
				Warden::Strategies.add(:basic, Strategies::Basic)
			end

			def self.configure(app, *args)
				options = args.last.is_a?(Hash) ? args.pop : {}
				type = args[0] || :basic
				user_class = options.delete(:user_class) || ::User
				redirect = options.delete(:redirect) || '/login'
				case type
				when :basic
					strategies = [:basic]
				when :form
					strategies = [:password]
				when :token
					strategies = [:token, :password]
				end
				app.use Warden::Manager do |config|
					config.default_scope = :user
					config.failure_app = self.fail(type)
					config[:user_class] = user_class
					config.scope_defaults(
						:user,
						:strategies => strategies,
						:action       => redirect
					)
 				end
 				if strategies.include? :password
	 				setup_cookie(app, user_class, options)
	 				setup_omniauth(app, options)
	 			end
			end

			def self.fail(type)
				auth_fail  = case type
				when :basic
					->(env) {[401, {"WWW-AUTHENTICATE" => "Basic realm=\"#{env['warden.options'][:attempted_path]}\""}, ["Auth"]] }
				when :form
					->(env) {[302, {"LOCATION" => env['warden.options'][:action]} , []] }
				when :token
					->(env) {[401, {"WWW-AUTHENTICATE" => "Token"}, []] }
				end
				->(env) { auth_fail.call(env) }
			end
			
			def self.setup_cookie(app, user_class, options)
				cookie = options.delete(:cookie) || {secret:'secr3t'}
				app.use Rack::Session::Cookie, cookie
				Warden::Manager.serialize_into_session do |user|
					user.id
				end
				Warden::Manager.serialize_from_session do |id|
					user_class.find_by_id(id)
				end
				app.plugin :csrf, raise: true, skip_if: lambda { |request|
					request.env.key? 'HTTP_AUTHORIZATION'
				}
			end

			def self.setup_omniauth(app, options)
				if providers = options.delete(:omniauth)
					app.use OmniAuth::Builder do
						provider :developer unless app.production?
						providers.each do |name|
							key = ENV["API_#{name.to_s.upcase}_KEY"]
							secret = ENV["API_#{name.to_s.upcase}_SECRET"]
							provider name, key, secret
						end
					end
				end
			end

			module InstanceMethods

				def authenticate!
					return current_user if current_user
					user = warden.authenticate!
					set_user(user)
					user
				end
				
				def unauthenticate!
					#lifted from devise
					warden.raw_session.inspect # Without this inspect here. The session does not clear.
					warden.logout(scope)
					warden.clear_strategies_cache!(scope: scope)
				end

				def current_user
					warden.user
				end

				def set_user(user)
					warden.set_user(user)
				end

				def sign_in &block
					user = authenticate!
					request.is(&block) if block
					user
				end

				def sign_out &block
					unauthenticate!
					request.response.status = 204
					request.is(&block) if block
				end

				private

				def scope
					:user
				end

				def warden
					request.env['warden']
				end

				def session_path
					roda_class.opts[:session_path].to_s
				end

			end

		end

		module Strategies

			class Base < Warden::Strategies::Base

				def success!(user)
					user.authentic! if user.respond_to?(:authentic!)
					super
				end

				def authenticate!
					user = warden.config[:user_class].authentic?(credentials)
					user.nil? ? fail!("Could not log in") : success!(user)
				end

				private

				def warden
					@env['warden']
				end

				def credentials_from_basic
					header = authorization_header
					return unless header && header =~ /\ABasic (.*)/m
					username, password = Base64.decode64($1).split(/:/, 2)
					return unless username and password
					{ 'username' => username, 'password' => password }
				end

				def credentials_from_form
					request.media_type == "application/x-www-form-urlencoded" && params
				end

				def credentials_from_body
					if request.body
						body = request.body.read
						!body.empty? && JSON.parse(body)
					end
				end

				def token_from_auth_header
					return unless header = authorization_header
					match = header =~ /\AAuth (.*)/m
					match && { 'token' => $1 }
				end

				def authorization_header
					@env['HTTP_AUTHORIZATION'] || @env['X-HTTP_AUTHORIZATION'] || @env['X_HTTP_AUTHORIZATION'] || @env['REDIRECT_X_HTTP_AUTHORIZATION']
				end

			end


			class Password < Base

				def valid?
					credentials['username'] && credentials['password']
				end

				private

				def credentials
					@credentials ||= credentials_from_form || credentials_from_body || {}
				end

			end

			class Basic < Password

				def valid?
					credentials['username'] && credentials['password']
				end

				# def result
				# 	:redirect
				# end

				private

				def credentials
					@credentials ||= credentials_from_basic || {}
				end

			end


			class Token < Base

				def valid?
					credentials['token']
				end

				private

				def credentials
					@credentials ||= token_from_auth_header || {}
				end

			end

		end

		register_plugin(:auth, Auth)

	end


end
