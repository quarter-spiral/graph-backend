require 'grape'

module Graph::Backend
  class API < ::Grape::API
    version 'v1', :using => :path, :vendor => 'quarter-spiral'

    format :json
    default_format :json

    rescue_from Graph::Backend::Error
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

    get "/entities/:uuid1/:relationship/:uuid2" do
      error!('Not found', 404) unless Relation.exists?(params[:relationship], params[:uuid1], params[:uuid2])
    end

    post "/entities/:uuid1/:relationship/:uuid2" do
      Relation.create(params[:relationship], params[:uuid1], params[:uuid2])
      ''
    end
  end
end
