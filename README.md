Roda plugin for Authentication
=============

### Quick start

Install gem with

    gem 'roda-auth'          #Gemfile


Create rack app 

```ruby
#api.ru

require 'roda/auth'

class App < Roda
  
  # :user_class defaults to ::User
  
  plugin :auth, :form, user_class: MyUser, redirect: '/login'
  
  route do |r|
    r.post 'login' do
      sign_in
    end
    r.get 'login' do
      #render login form
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
  
  #optional - used for  generating/updating auth tokens or tracking logins
  
  def authentic!
    #call for each successful authentication request
  end
  
end
  
