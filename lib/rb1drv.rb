require "excon"
require "oauth2"
require "rb1drv/version"

module Rb1drv
  # Base class to support oauth2 authentication and sending simple API requests.
  #
  # Call +#root+ or +#get+ to get an +OneDriveDir+ or +OneDriveFile+ to wotk with.
  class OneDrive
    attr_reader :oauth2_client, :logger, :access_token, :conn, :is_21vianet_version
    # Instanciates with app id and secret.
    def initialize(client_id, client_secret, callback_url, logger = nil, is_21vianet_version = false)
      @client_id = client_id
      @client_secret = client_secret
      @callback_url = callback_url
      @is_21vianet_version = is_21vianet_version
      @logger = logger
      @oauth2_client = if @is_21vianet_version
        OAuth2::Client.new client_id, client_secret,
          authorize_url: "https://login.chinacloudapi.cn/organizations/oauth2/v2.0/authorize",
          token_url: "https://login.chinacloudapi.cn/organizations/oauth2/v2.0/token"
      else
        OAuth2::Client.new client_id, client_secret,
          authorize_url: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
          token_url: "https://login.microsoftonline.com/common/oauth2/v2.0/token"
      end
      endpoint = @is_21vianet_version ? "https://microsoftgraph.chinacloudapi.cn/" : "https://graph.microsoft.com/"
      # noinspection RubyYardParamTypeMatch
      @conn = Excon.new(endpoint, persistent: true, idempotent: true)
      @conn.logger = @logger if @logger
    end

    # Issues requests to API endpoint.
    #
    # @param uri [String] relative path of the API
    # @param data [Hash] JSON data to be post
    # @param verb [Symbol] HTTP request verb if data is given
    #
    # @return [Hash] response from API.
    def request(uri, data = nil, verb = :post)
      @logger&.info(uri)
      auth_check
      query = {
        path: File.join("v1.0/me/", CGI.escape(uri)),
        headers: {
          'Authorization': "Bearer #{@access_token.token}"
        }
      }
      if data
        query[:body] = JSON.generate(data)
        query[:headers]["Content-Type"] = "application/json"
        @logger&.info(query[:body])
        verb = :post unless [:post, :put, :patch, :delete].include?(verb)
        response = @conn.send(verb, query)
      else
        response = @conn.get(query)
      end
      JSON.parse(response.body)
    end
  end

  class << self
    attr_accessor :raise_on_failed_request
  end

  self.raise_on_failed_request = false
end

require "rb1drv/errors"
require "rb1drv/auth"
require "rb1drv/onedrive"
require "rb1drv/onedrive_item"
require "rb1drv/onedrive_dir"
require "rb1drv/onedrive_file"
require "rb1drv/onedrive_404"
