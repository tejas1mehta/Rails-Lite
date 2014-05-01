require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = Params.new(req, route_params)
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    unless already_built_response?
      @res.content_type = type
      @res.body = content
      @already_built_response = true
      session.store_session(@res)
    end
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # set the response status code and header
  def redirect_to(url)
    unless already_built_response?
      @res.status = 302
      @res["Location"] = url
      @already_built_response = true
      session.store_session(@res)
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)

    template_file = File.read("views/#{self.class.name.underscore}/#{template_name}.html.erb")
    compiled_erb = ERB.new(template_file)
    b = binding()

    erb_result = compiled_erb.result(b)

    render_content(erb_result, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render name if !already_built_response?
  end
end
