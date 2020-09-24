
module Asu
  class Auth
    attr_accessor :username
    attr_accessor :password
    attr_accessor :site
    attr_accessor :context_path
    attr_accessor :auth_type

    def initialize(
      username: ENV['USERNAME'],
      api_token: ENV['API_TOKEN'],
      site: ENV['SITE'],
      context_path: ENV['CONTEXT_PATH'],
      auth_type: ENV['AUTH_TYPE'].to_sym
    )
      @username = username
      @password = api_token
      @site = site
      @context_path = context_path
      @auth_type = auth_type
    end

    def options
      {
        username: username,
        password: password,
        site: "https://#{site}",
        context_path: context_path,
        auth_type: auth_type
      }
    end

    def client
      @client ||= JIRA::Client.new(options)
    end

    def reset_client
      @client = JIRA::Client.new(options)
    end
  end
end
