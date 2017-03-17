module Triglav
  module Consumer
    class StubClient
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
      end

      def fetch_messages(offset, job_id, limit: 100)
        [TriglavClient::JobMessageEachResponse.new.tap {|message|
          message.id = 1
          message.job_id = 1
          message.time = 1476025200
          message.timezone = "+09:00"
        }]
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
        example_job
      end

      # Get a job
      #
      # @param [String or Integer] id_or_uri job id or uri
      # @return [TriglavClient::JobResponse]
      def get_job(id_or_uri)
        example_job
      end

      def get_last_message_id
        TriglavClient::LastMessageIdResponse.new.tap {|resp| resp.id = 1 }
      end

      private

      def example_job
        TriglavClient::JobResponse.new.tap do |job|
          job.id = 1
          job.uri = "http://localhost:3000/app/project//taskset/1/task/"
          job.input_resources = [TriglavClient::ResourceResponse.new.tap do |resource|
            resource.id = 1
            resource.uri = "https://bigquery.cloud.google.com/table/project_id:dataset.table"
            resource.unit = "daily"
            resource.timezone = "+09:00"
            resource.span_in_days = 32
            resource.consumable = true
            resource.notifiable = false
          end]
          job.output_resources = [TriglavClient::ResourceResponse.new.tap do |resource|
            resource.id = 1
            resource.uri = "hdfs://10.66.40.24:8020/tmp/test"
            resource.uri = "https://bigquery.cloud.google.com/table/project_id:dataset.table"
            resource.unit = "daily"
            resource.timezone = "+09:00"
            resource.span_in_days = 32
            resource.consumable = false
            resource.notifiable = false
          end]
        end
      end
    end
  end
end
