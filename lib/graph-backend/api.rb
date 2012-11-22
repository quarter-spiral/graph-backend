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

      def extract_meta_information
        meta = params[:meta]
        return {} unless meta
        raise Error.new("Meta information must be an object!") unless meta.kind_of?(Hash)
        meta.to_hash
      end

      def relationship_type
        params[:relationship]
      end

      def uuid1
        params[:uuid1]
      end

      def uuid2
        params[:uuid2]
      end

      def direction
        params[:direction]
      end
    end

    before do
      unless request.env['REQUEST_METHOD'] == 'OPTIONS'
        error!('Unauthenticated', 403) unless request.env['HTTP_AUTHORIZATION']
        token = request.env['HTTP_AUTHORIZATION'].gsub(/^Bearer\s+/, '')
        error!('Unauthenticated', 403) unless connection.auth.token_valid?(token)
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
        relation = Relation.get(relationship_type, uuid1, uuid2)
        meta = Relation.get_meta_data(relation)
        Relation.new(params[:uuid1], params[:uuid2], params[:relationship], meta).to_hash
      end

      post "/:uuid1/:relationship/:uuid2" do
        if Relation.exists?(relationship_type, uuid1, uuid2, direction)
          relations = Relation.update_meta(relationship_type, uuid1, uuid2, direction, extract_meta_information, merge: true)
          status 304
          relations.map &:to_hash
        else
          relations = Relation.create(relationship_type, uuid1, uuid2, direction, extract_meta_information)
          relations.map &:to_hash
        end
      end

      put "/:uuid1/:relationship/:uuid2" do
        not_found! unless Relation.exists?(relationship_type, uuid1, uuid2, direction)

        relations = Relation.update_meta(relationship_type,  uuid1, uuid2, direction, extract_meta_information, merge: false)
        relations.map &:to_hash
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
