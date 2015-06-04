require "minitest/autorun"
require 'rack/test'
require "roda"
require "json"
require "stringio"
require "rack/test"
require 'roda/auth'

module TestHelpers
	def app(type=nil, &block)
		case type
		when :new
			@app = _app{route(&block)}
		when :bare
			@app = _app(&block)
		when Symbol
			@app = _app do
				plugin type
				route(&block)
			end
		else
			@app ||= _app{route(&block)}
		end
	end
	
	def request
		Rack::MockRequest.new(@app)
	end
	
	def _app(&block)
		c = Class.new(Roda)
		c.class_eval(&block)
		c
	end

	def form_login(cred = valid_credentials)
		opts = setup_csrf :params => cred
		request.post('/login', opts)
	end

	
	def valid_credentials
		{username:'foo', password:'bar'}
	end
	
	def http_auth(c)
		Base64.encode64("#{c[:username]}:#{c[:password]}")
	end
	
	def invalid_credentials
		{username:'foo', password:'baz'}
	end
	
	def setup_csrf(env)
		if env['REQUEST_METHOD'] != 'GET'
			env['rack.session'] = {}
			token = Rack::Csrf.token(env)
			env['HTTP_X_CSRF_TOKEN'] = token
		end
		env
	end

	class Mock
	
		attr_accessor :id, :name, :price
	
		def self.find(params)
			if params[:page] || params[:album_id]
				[new(1, 'filtered' + params[:album_id].to_s )]
			else
				[new(1, 'foo'), new(2, 'bar')]
			end
		end
	
		def self.create_or_update(atts)
			if id = atts.delete(:id)
				self[id].save(atts)
			else
				self.new(1, atts[:name], atts[:price])
			end
		end
	
		def self.[](id)
			if id
				if id.to_i > 12
					raise DBNotFoundError
				end
				id == 'new' ? new : new(id.to_i, name: 'foo')
			end
		end
	
		def initialize(id = nil, name = nil, price = nil)
			@id = id
			@name = name
			@price = price
		end
	
		def save(atts)
			self.name = atts[:name]
			self.price = atts[:price]
			self
		end
	
		def destroy
			''
		end
	
		def to_json(state = nil)
			{id: @id, name: @name, price: @price, class: self.class.name }.to_json(state)
		end
	
	end
	
	class Album < Mock ; end
	class Artist < Mock ; end
	
	class DBNotFoundError < StandardError ; end
	
	class User
	
		attr_accessor :id, :token, :username, :password
	
		## required

		def self.authentic?(credentials)
			if credentials['token']
				self.db[:tokens][credentials['token']]
			else
				u = self.db[:users][credentials['username']]
				u if u && u.password == credentials['password']
			end
		end
		
		def authentic!
			if !@token
				require 'securerandom'
				@token = SecureRandom.uuid
				self.class.db[:tokens][@token] = self
			end
		end
	
		## test dummy
			
		def initialize(args)
			@username = args[:username]
			@password = args[:password]
			@token = args[:token]
			@id = self.class.db[:users].length + 1
		end
	
		def self.db
			@@db ||= {users: {}, tokens: {}}
		end
		
		def self.find_by_id(id)
			db[:users].values.find do |u|
				u.id == id
			end
		end

		def to_json(state = nil)
			{id: @id, username: @username, token: @token}.to_json(state)
		end
	
	end

	
	
end
