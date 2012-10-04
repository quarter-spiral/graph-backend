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

      def not_found!
        error!('Not found', 404)
      end
    end

    before do
      error!('Unauthenticated', 403) unless request.env['HTTP_AUTHORIZATION']
      token = request.env['HTTP_AUTHORIZATION'].gsub(/^Bearer\s+/, '')
      error!('Unauthenticated', 403) unless connection.auth.token_valid?(token)
    end

    get "version" do
      api.version
    end

    get "roles/:role" do
      Node.find_by_role(params[:role]).map do |node|
        node['data']['uuid']
      end
    end

    namespace '/entities' do
      delete "/:uuid" do
        Node.delete(params[:uuid])
        ''
      end

      get "/:uuid/roles" do
        Node.get_roles(params[:uuid])
      end

      post "/:uuid/roles/:role" do
        Node.add_role(params[:uuid], params[:role])
        ''
      end

      delete "/:uuid/roles/:role" do
        Node.remove_role(params[:uuid], params[:role])
        ''
      end

      get "/:uuid1/:relationship/:uuid2" do
        not_found! unless Relation.exists?(params[:relationship], params[:uuid1], params[:uuid2])
        ''
      end

      post "/:uuid1/:relationship/:uuid2" do
        throw(:error, :status => 304) if Relation.exists?(params[:relationship], params[:uuid1], params[:uuid2], params[:direction])
        Relation.create(params[:relationship], params[:uuid1], params[:uuid2], params[:direction])
        ''
      end

      delete "/:uuid1/:relationship/:uuid2" do
        not_found! unless Relation.delete(params[:relationship], params[:uuid1], params[:uuid2])
        ''
      end

      get "/:uuid1/:relationship" do
        Relation.list_for(params[:relationship], params[:uuid1], params[:direction])
      end
    end
  end
end
