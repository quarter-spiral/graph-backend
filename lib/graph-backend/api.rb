require 'grape'

module Graph::Backend
  class API < ::Grape::API
    version 'v1', :using => :path, :vendor => 'quarter-spiral'

    format :json
    default_format :json

    error_format :json

    helpers do
      def connection
        @connection ||= Connection.create
      end
    end

    get "version" do
      api.version
    end

    get "roles/:role" do
      Node.find_by_role(params[:role]).map do |node|
        node['data']['uuid']
      end
    end

    post "/entities/:uuid/roles/:role" do
      Node.add_role(params[:uuid], params[:role])
      ''
    end

    delete "/entities/:uuid/roles/:role" do
      Node.remove_role(params[:uuid], params[:role])
      ''
    end
  end
end
