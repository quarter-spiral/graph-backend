require 'grape'
require 'grape_newrelic'

module Graph::Backend
  class API < ::Grape::API
    use GrapeNewrelic::Instrumenter
    version 'v1', :using => :path, :vendor => 'quarter-spiral'

    format :json
    default_format :json

    default_error_formatter :json

    rescue_from :all do |e|
      if ENV['RACK_ENV'] == 'development' || ENV['RACK_ENV'] == 'production'
        $stderr.puts "#{e.message}\n\n#{e.backtrace.join("\n")}"
      end

      if e.kind_of?(Graph::Backend::Error)
        Rack::Response.new({error: e.message, backtrace: e.backtrace}.to_json, 500, { 'Content-type' => 'application/json' }).finish
      else
        raise e
      end
    end

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

      def empty_body
        {}
      end

      def own_data?(uuid)
        @token_owner['uuid'] == uuid
      end

      def system_level_privileges?
        @token_owner['type'] == 'app'
      end

      def is_authorized_to_access?(uuid)
        system_level_privileges? || own_data?(uuid)
      end

      def prevent_access!
        error!('Unauthenticated', 403)
      end

      def owner_only!(uuid = params[:uuid])
        prevent_access! unless is_authorized_to_access?(uuid)
      end

      def system_privileges_only!
        prevent_access! unless system_level_privileges?
      end

      def public_resource?(request)
        request.env['PATH_INFO'].start_with?('/v1/public/')
      end
    end

    before do
      unless request.env['REQUEST_METHOD'] == 'OPTIONS' || public_resource?(request)
        prevent_access! unless request.env['HTTP_AUTHORIZATION']
        token = request.env['HTTP_AUTHORIZATION'].gsub(/^Bearer\s+/, '')
        @token_owner = connection.auth.token_owner(token)
        prevent_access! unless @token_owner
      end
    end

    get "/public/__PING__" do
      {'root_id' => connection.neo4j.get_root['self'].split('/').last}
    end

    get "version" do
      api.version
    end

    get "roles/:role" do
      system_privileges_only!

      Node.find_by_role(params[:role]).map do |node|
        node['data']['uuid']
      end
    end

    namespace '/entities' do
      delete "/:uuid" do
        owner_only!

        Node.delete(params[:uuid])
        empty_body
      end

      get "/:uuid/roles" do
        owner_only!

        Node.get_roles(params[:uuid])
      end

      post "/:uuid/roles/:role" do
        owner_only!

        Node.add_role(params[:uuid], params[:role])
        empty_body
      end

      delete "/:uuid/roles/:role" do
        owner_only!

        Node.remove_role(params[:uuid], params[:role])
        empty_body
      end

      get "/:uuid1/:relationship/:uuid2" do
        owner_only!(params[:uuid1])

        not_found! unless Relation.exists?(params[:relationship], params[:uuid1], params[:uuid2])
        relation = Relation.get(relationship_type, uuid1, uuid2)
        meta = Relation.get_meta_data(relation)
        Relation.new(params[:uuid1], params[:uuid2], params[:relationship], meta).to_hash
      end

      post "/:uuid1/:relationship/:uuid2" do
        system_privileges_only!

        if Relation.exists?(relationship_type, uuid1, uuid2, direction)
          relations = Relation.update_meta(relationship_type, uuid1, uuid2, direction, extract_meta_information, merge: true)
          status(relations.any? {|r| r.dirty?} ? 200 : 304)
          relations.map &:to_hash
        else
          relations = Relation.create(relationship_type, uuid1, uuid2, direction, extract_meta_information)
          relations.map &:to_hash
        end
      end

      put "/:uuid1/:relationship/:uuid2" do
        system_privileges_only!

        not_found! unless Relation.exists?(relationship_type, uuid1, uuid2, direction)

        relations = Relation.update_meta(relationship_type,  uuid1, uuid2, direction, extract_meta_information, merge: false)
        relations.map &:to_hash
      end

      delete "/:uuid1/:relationship/:uuid2" do
        system_privileges_only!

        not_found! unless Relation.delete(params[:relationship], params[:uuid1], params[:uuid2])
        empty_body
      end

      get "/:uuid1/:relationship" do
        owner_only!(params[:uuid1])

        Relation.list_for(params[:relationship], params[:uuid1], params[:direction])
      end
    end

    get "/query/*path" do
      system_privileges_only!

      uuids = env['PATH_INFO'].gsub(/^.*\/query\//, '').split('/')
      query = Query.new(uuids, params[:query])
      result = connection.neo4j.execute_query(query.to_cypher)['data']
      result
    end
  end
end
