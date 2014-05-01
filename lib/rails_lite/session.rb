require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @req = req
    cookie = @req.cookies.select{ |cookie| cookie.name == '_rails_lite_app' }.first
    @current_cookie = (!cookie.nil? ? JSON.parse(cookie.value) : {} )
  end

  def [](key)
    @current_cookie[key]
  end

  def []=(key, val)
    @current_cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    @cookie_json = @current_cookie.to_json
    res.cookies << WEBrick::Cookie.new("_rails_lite_app", @cookie_json)
  end
end
