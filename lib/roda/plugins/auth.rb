require 'base64'
require 'warden'
require 'roda'

class Roda
	
	module RodaPlugins

		module Auth
			
			def self.load_dependencies(app, *args, &block)
				Warden::Strategies.add(:token, Strategies::Token)
				Warden::Strategies.add(:password, Strategies::Password)
				Warden::Strategies.add(:basic, Strategies::Basic)
			end
			
			def self.configure(app, *args)
				options = args.last.is_a?(Hash) ? args.pop : {}
				user_class = options.delete(:user_class) || ::User
				type = args[0] || :basic
				redirect = options.delete(:redirect) || '/unautenticated'
				case type
				when :basic
					strategies = [:basic]
				when :form
					strategies = [:password]
					app.use Rack::Session::Cookie, secret:'foo'
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
			end
			
			def self.fail(type)
				auth_fail  = case type
				when :basic
					->(env) {[401, {"WWW-AUTHENTICATE" => "Basic: Realm=\"#{env['warden.options'][:attempted_path]}\""}, []] }
				when :form
					->(env) {[302, {"HTTP-LOCATION" => env['warden.options'][:action]} , []] }
				when :token
					->(env) {[401, {"WWW-AUTHENTICATE" => "\"Token\""}, []] }
				end
				->(env) { auth_fail.call(env) }
			end
						
			module InstanceMethods
				
				def authenticate!
					user = warden.authenticate!
					warden.set_user(user)
				end
				
				def current_user
					warden.user
				end
				
				def sign_in &block
					raise RodaError 'sign_in with POST only' unless request.env['REQUEST_METHOD'] == "POST"
					user = warden.authenticate!
					warden.set_user(user)
					request.is(&block) if block
					request.response.status = 201
					user
				end
				
				def sign_out &block
					warden.set_user(nil)
					request.is(&block) if block
					request.response.status = 204
				end
				
				private
				
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
						
				def success!(u)
					u.authentic! if u.respond_to?(:authentic!)
					super
				end
				
				def authenticate!
					u = warden.config[:user_class].authentic?(credentials)
					u.nil? ? fail!("Could not log in") : success!(u)
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
					request.body && JSON.parse(request.body.string)
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
					@credentials if @credentials
					@credentials = credentials_from_form || credentials_from_body || {}
				end
		
			end
			
			class Basic < Password
							
				def valid?
					credentials['username'] && credentials['password']
				end
				
				private
			
				def credentials
					@credentials if @credentials
					@credentials = credentials_from_basic || {}
				end
			
			end

		
			class Token < Base
		
				def valid?
					credentials['token']
				end
				
				private
		
				def credentials
					@credentials if @credentials
					@credentials = token_from_auth_header || {}
				end
		
			end
		
		end
		
		register_plugin(:auth, Auth)
		
	end
	

end
