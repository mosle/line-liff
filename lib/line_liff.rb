require "line-bot-api"
require "line_liff/version"

unless Line::Bot::HTTPClient.method_defined? :put
  module Line
    module Bot
      class HTTPClient
          def put(url, payload, header = {})
            uri = URI(url)
            http(uri).put(uri.request_uri, payload, header)
          end
      end
    end
  end
end


unless Line::Bot::Request.method_defined? :put
  module Line
    module Bot
      class Request
          def put
            httpclient.put(endpoint + endpoint_path, payload, header)
          end
      end
    end
  end
end if defined?(Line::Bot::Request)

unless Line::Bot::Client.method_defined? :put
  module Line
    module Bot
      class Client
        
        def put(endpoint_base,endpoint_path, payload = nil,headers={})
          if defined?(Line::Bot::Request)
            if self.class.method_defined? :credentials?
              raise Line::Bot::API::InvalidCredentialsError, 'Invalidates credentials' unless credentials?
            else
              channel_token_required
            end
            request = Line::Bot::Request.new do |config|
              config.httpclient     = httpclient
              config.endpoint       = endpoint_base
              config.endpoint_path  = endpoint_path
              config.credentials    = credentials
              config.payload        = payload if payload
            end
      
            return request.put
          else
            headers = Line::Bot::API::DEFAULT_HEADERS.merge(headers)
            httpclient.put(endpoint_base + endpoint_path, payload, headers)
          end
        end
      end
    end
  end
end

module Line
  module Bot
    class LiffClient < Line::Bot::Client
      @@api_version = "v1"

      def self.create_by_line_bot_client line_bot_client
        self.new{|config|
            config.channel_secret = line_bot_client.channel_secret
            config.channel_token = line_bot_client.channel_token
        }
      end
      #def self.api_version
      #  @@api_version
      #end
      def self.default_endpoint
        "https://api.line.me/liff/#{@@api_version}/apps"
      end
      def endpoint
        @endpoint ||= self.class.default_endpoint
      end
      def get_liffs
        endpoint_path  = ""
        get endpoint,endpoint_path,credentials
      end

      def create_liff type,url,description = nil,features = {}
        payload = {
            view:{
                type:type,url:url
            },
            description:description,
            features:features
        }
        post endpoint,"", payload.to_json,credentials
      end
      def update_liff liff_id,type=nil,url=nil,description = nil,features = {}
        payload = {}
        payload[:view] = {type:type,url:url}.reject { |k,v| v.nil? }
        payload[:description] = description
        payload[:features] = features
        payload.reject!{|k,v| v.nil? or v.length == 0}
        put endpoint,"/#{liff_id}", payload.to_json,credentials
      end

      def delete_liff liff_id
        delete endpoint, "/#{liff_id}",credentials
      end
    end
  end
end
