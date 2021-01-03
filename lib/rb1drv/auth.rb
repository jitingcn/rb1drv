module Rb1drv
  class OneDrive
    # Gets authorize URL to start authentication process
    #
    # @return [String] the authorize URL
    def auth_url
      if @is_21vianet_version
        @oauth2_client.auth_code.authorize_url(
          redirect_uri: @callback_url,
          scope: "openid offline_access https://microsoftgraph.chinacloudapi.cn/Files.ReadWrite.All"
        )
      else
        @oauth2_client.auth_code.authorize_url(
          redirect_uri: @callback_url,
          scope: "openid offline_access https://graph.microsoft.com/Files.ReadWrite.All"
        )
      end
    end

    # Gets access token from authorize code
    #
    # @return [OAuth2::AccessToken] the access token
    def auth_access(auth_code)
      @access_token = @oauth2_client.auth_code.get_token(auth_code, redirect_uri: @callback_url)
    end

    # Loads previously retrieved access token from Hash
    #
    # @return [OAuth2::AccessToken] the access token
    def auth_load(access_token)
      @access_token = OAuth2::AccessToken.from_hash(@oauth2_client, access_token)
      if @access_token.params["expiry"]
        expiry = DateTime.parse(@access_token.params["expiry"]).to_time
        @access_token.instance_variable_set :@expires_at, expiry.to_i
        @access_token.instance_variable_set :@expires_in, (expiry - Time.now).to_i
      end
      @access_token = @access_token.refresh! if @access_token.expired?
      @access_token
    end

    def auth_check
      @access_token = @access_token.refresh! if @access_token.expired?
    end
  end
end
