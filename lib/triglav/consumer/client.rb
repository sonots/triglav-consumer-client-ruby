require 'triglav_client'

# This Triglav client connects to triglav API, and
# automatically authenticates when it is required, and
# stores the token per process on memory.
#
# Re-authenticate automatically if token is expired.
#
#     client = Triglav::Consumer::Client.new(url:, username:, password:, authenticator: 'local')
#     client.create_or_update_job(uri, input_resources, output_resources)
#
#     client = Triglav::Consumer::Client.new(url:, username:, password:, authenticator: 'local')
#     client.fetch_messsages(offset, job_id, limit: limit)
module Triglav
  module Consumer
    class Client
      class Error < StandardError
        attr_reader :cause
        def initialize(message, cause)
          @cause = cause
          super(message)
        end
      end
      class AuthenticationError < Error; end
      class ConnectionError < Error; end

      attr_reader :url, :username, :password, :authenticator, :logger

      # Initialize TriglavConsumerClient
      #
      # @param [Hash] paramss
      # @option params [String] :url
      # @option params [String] :username
      # @option params [String] :password
      # @option params [String] :authenticator 'local' or 'ldap'
      # @option params [Logger] :logger
      def initialize(params = {})
        @url = params[:url]
        @username = params[:username]
        @password = params[:password]
        @authenticator = params[:authenticator]
        @logger = params[:logger] || ::Logger.new(nil)

        config = TriglavClient::Configuration.new do |config|
          uri = URI.parse(url)
          config.scheme = uri.scheme
          config.host = "#{uri.host}:#{uri.port}"
          config.timeout = params[:timeout] unless params[:timeout].nil?
          config.debugging = params[:debugging] unless params[:debugging].nil?
          config.verify_ssl = params[:verify_ssl] unless params[:verify_ssl].nil?
          config.verify_ssl_host = params[:verify_ssl_host] unless params[:verify_ssl_host].nil?
          config.ssl_ca_cert = params[:ssl_ca_cert] unless params[:ssl_ca_cert].nil?
          config.cert_file = params[:cert_file] unless params[:cert_file].nil?
          config.key_file = params[:key_file] unless params[:key_file].nil?
        end
        @api_client = TriglavClient::ApiClient.new(config)
        initialize_current_token
      end

      # Fetch messages
      #
      # @param [Integer] offset
      # @param [Integer] job_id
      # @param [Integer] limit
      # @return [Array] array of messages
      # @see TriglavClient::JobMessageEachResponse
      #   id
      #   job_id
      #   time
      #   timezone
      def fetch_messages(offset, job_id, limit: 100)
        logger.debug { "ApiClient#fetch_job_messages(#{offset}, #{job_id}, limit: #{limit})" }
        messages_api = TriglavClient::JobMessagesApi.new(@api_client)
        with_token { messages_api.fetch_job_messages(offset, job_id, {limit: limit}) }
      end

      # Create or update a job
      #
      # @param [TriglavClient::JobRequest] job_request job request object
      #
      #    job = TriglavClient::JobRequest.new
      #    job.id = job_id
      #    job.uri = job_uri
      #    job.input_resources = [{
      #      id: input_resource_id,
      #      uri: input_resource_uri,
      #      unit: input_resource_unit,
      #      timezone: input_resource_timezone,
      #    }]
      #    job.output_resources = [{
      #      id: output_resource_id,
      #      uri: output_resource_uri,
      #      unit: output_resource_unit,
      #      timezone: output_resource_timezone,
      #    }]
      #
      def create_or_update_job(job_request)
        logger.debug { "ApiClient#create_or_update_job(#{job_request.to_hash})" }
        jobs_api = TriglavClient::JobsApi.new(@api_client)
        with_token { jobs_api.create_or_update_job(job_request) }
      end

      # Get a job
      #
      # @param [String or Integer] id_or_uri job id or uri
      # @return [TriglavClient::JobResponse]
      def get_job(id_or_uri)
        logger.debug { "ApiClient#get_job(#{id_or_uri})" }
        jobs_api = TriglavClient::JobsApi.new(@api_client)
        with_token { jobs_api.get_job(id_or_uri) }
      end

      # Delete a job
      #
      # @param [String or Integer] id_or_uri job id or uri
      # @return [nil]
      def delete_job(id_or_uri)
        logger.debug { "ApiClient#delete_job(#{id_or_uri})" }
        jobs_api = TriglavClient::JobsApi.new(@api_client)
        with_token { jobs_api.delete_job(id_or_uri) }
      end

      def get_last_message_id
        logger.debug { "ApiClient#get_last_job_message_id" }
        messages_api = TriglavClient::JobMessagesApi.new(@api_client)
        with_token { messages_api.get_last_job_message_id }
      end

      private

      # Authenticate
      #
      # Get token per process on memory
      def authenticate
        logger.debug { 'ApiClient#authenticate' }
        auth_api = TriglavClient::AuthApi.new(@api_client)
        credential = TriglavClient::Credential.new(
          username: username, password: password, authenticator: authenticator
        )
        handle_auth_error do
          logger.debug { 'TriglavClient::AuthApi' }
          result = auth_api.create_token(credential)
          token = {access_token: result.access_token}
          update_current_token(token)
        end
      end

      def initialize_current_token
        @current_token = {
          access_token: (@api_client.config.api_key['Authorization'] = String.new),
        }
      end

      def update_current_token(token)
        @current_token[:access_token].replace(token[:access_token])
      end

      def has_token?
        @current_token[:access_token].nil? or @current_token[:access_token].empty?
      end

      def handle_auth_error(&block)
        begin
          yield
        rescue TriglavClient::ApiError => e
          if e.code == 0
            raise ConnectionError.new("Could not connect to #{url}", e)
          elsif e.message == 'Unauthorized'.freeze
            raise AuthenticationError.new("Failed to authenticate on triglav API.".freeze, e)
          else
            # @todo: retry?
            raise Error.new(e.message, e)
          end
        end
      end

      def with_token(&block)
        authenticate unless has_token?
        begin
          yield
        rescue TriglavClient::ApiError => e
          if e.code == 0
            raise ConnectionError.new("Could not connect to #{url}", e)
          elsif e.message == 'Unauthorized'.freeze
            authenticate
            retry
          else
            # @todo: retry?
            raise Error.new(e.message, e)
          end
        end
      end
    end
  end
end
