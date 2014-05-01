require 'uri'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  attr_reader :params, :permitted_params

  def initialize(req, route_params = {})
    @params = route_params
    parse_www_encoded_form(req.body) unless req.body.nil?
    parse_www_encoded_form(req.query_string) unless req.query_string.nil?
    @permitted_params = {}
  end

  def [](key)
    @params[key.to_sym]
  end

  def permit(*keys)
    keys.each do |key|
      @permitted_params[key] = self.params[key]
    end

    return @permitted_params
  end

  def require(key)
    if self.params.keys.include?(key)
      return self.params
    else
      raise Params::AttributeNotFoundError
    end
  end

  def permitted?(key)
    self.permitted_params.keys.include?(key)
  end

  def to_s
    #p @params
    @params.to_json.to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    params_array = URI::decode_www_form(www_encoded_form)
    params_array.each do |param_el|
         keys = parse_key(param_el.first)
         val = param_el.last
         next_params = nested_hash(keys, val)
         @params = @params.deep_merge(next_params)
    end
  end

  def nested_hash(keys, val)
    return {keys.first.to_sym => val} if keys.length == 1

    return { keys.shift.to_sym => nested_hash(keys, val) }
  end
  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end
end
