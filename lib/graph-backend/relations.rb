module Graph::Backend
  module Relations
  end
end

require_relative './relations/base'
Dir[File.expand_path('../relations/*.rb', __FILE__)].each {|f| require f}
