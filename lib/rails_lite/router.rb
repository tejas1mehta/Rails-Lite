class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern, @http_method, @controller_class, @action_name =
     pattern, http_method, controller_class, action_name

  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    ( req.path =~ @pattern ) &&
    ( req.request_method.downcase.to_sym == @http_method )
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    route_params = {}
    params_match_data = pattern.match(req.path)
    params_match_data.names.each do |name_par|
      route_params[name_par.to_sym] = params_match_data[name_par]
    end
    @controller_class.new(req, res, route_params).invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      @routes << Route.new(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    route = @routes.select{|route| route.matches?(req)}
    return route.first
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    run_route = match(req)
    !!run_route ? run_route.run(req, res) : (res.status = 404)
  end
end
