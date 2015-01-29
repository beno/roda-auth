Roda plugin for Authentication
=============

### Status

This is a first stab at integrating Roda and Warden. It is by no means ready for real use.

### Quick start

Install gem with

    gem 'roda-auth'          #Gemfile


Create rack app 

```ruby
#api.ru

require 'roda/auth'

class App < Roda
  
  # supports 3 auth types: :basic (default), :form or :token
  # :user_class defaults to ::User
  # :redirect defaults to '/unauthenticated'
  
  plugin :auth, :form, user_class: MyUser, redirect: '/login'
  
  route do |r|
    r.post 'login' do
      sign_in do
        redirect "/private/profile/#{current_user}"
      end
    end
    r.get 'login' do
      #render login form
    end
    r.post 'logout' do
      sign_out
    end
    r.on 'public' do
      #public content
    end
    authenticate!
    r.on 'private' do
      #private content
    end
  end

end

class MyUser

  #required - should return either a valid user or nil
  
  def self.authentic?(credentials)
    #credentials is either {'username' => 'foo', 'password' => 'bar'} or {'token' => '123'}
    if token = credentials['token']
      self.find_by_token(token) #make sure to use a safe (constant time) method of looking up tokens
    else
      self.check_password(credentials['username'], credentials['password'])
    end
  end
  
  #required when using :form strategy (for sessions)
  
  def self.find_by_id(id)
    find(id)
  end
  
  #optional - used for  generating/updating auth tokens or tracking logins
  
  def authentic!
    #call for each successful authentication request
  end
  
end
  
