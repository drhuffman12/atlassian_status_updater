require 'net/http'
require 'uri'
require 'json'

module Asu
  class StatusChanger
    attr_accessor :auth

    def initialize # (auth)
      # @auth = auth
      @auth = Auth.new
    end

    # data = {
    #   "update": { "comment": [ { "add": { "body": "closing issue via drh script" } } ] },
    #   "transition": {"id": "6"} # aka 'Closed'
    # } if closable

    def change(ticket_key, status_id, comment = nil)
      # uri = ticket_uri(ticket_key)
      # uri.hostname.gsub('https://https//','https://')
      # uri = URI.parse("https://linuxacademy.atlassian.net/rest/api/3/issue/#{ticket_key}/transitions")
      uri = URI.parse("https://#{@auth.site}/rest/api/3/issue/#{ticket_key}/transitions")

      puts
      puts "uri: #{uri}"
      puts "uri.hostname: #{uri.hostname}"

      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@auth.username, @auth.password)
      request.content_type = "application/json"
      request["Accept"] = "application/json"

      # data = ticket_data(status_id, comment)
      data = ticket_status_data(status_id)

      try_post(uri, status_id, data, request)
      # request.body = JSON.dump(data)

      # req_options = { use_ssl: uri.scheme == "https" }

      # # Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
      # # # Net::HTTP.start(uri.hostname, 443, req_options) { |http| http.request(request) }
      # # # Net::HTTP.start(uri.hostname, req_options) { |http| http.request(request) }

      # # Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      # #   http.request(request)
      # # end

      # response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      #   http.request(request)
      # end
      
      # # http = Net::HTTP.new(@auth.site)
      # # http.send_request('POST', uri.hostname, data) # , req_options)


      # results = { ticket_key =>{
      #     status_id: status_id,
      #     response: {
      #       code: response.code,
      #       body: response.body
      #     }
      #   }
      # }

      # puts "results: #{results}"
      # puts

      # results
    rescue StandardError => err
      # begin
      #   data = ticket_status_data(status_id)
      #   try_post(uri, status_id, data, request)
      # rescue StandardError => err
        pp err.class
        pp err.message
        pp err.backtrace
        nil
      # end
    end

    private

    # def ticket_uri(ticket_key)
    #   # URI.parse("http://JIRA_URL:JIRA_PORT/rest/api/latest/issue/JIRA_ISSUE/transitions?expand=transitions.fields")
    #   # URI.parse("http://#{@auth.site}/rest/api/latest/issue/#{ticket_key}/transitions?expand=transitions.fields")

    #   URI.parse("https://#{@auth.site}/rest/api/3/issue/#{ticket_key}/transitions")
    # end

    def try_post(uri, status_id, data, request)
      request.body = JSON.dump(data)
      req_options = { use_ssl: uri.scheme == "https" }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      
      results = { ticket_key: {
          status_id: status_id,
          response: {
            code: response.code,
            body: response.body
          }
        }
      }

      puts "results: #{results}"
      puts

      results      
    end

    def ticket_status_data(status_id)
      {
        "transition" => { "id" => "#{status_id}" },
        # "fields": {
        #   "resolution": {
        #     # "name": "Fixed"
        #     "name": "Done"
        #   }
        # },
      }
    end

    def ticket_data(status_id, comment = '')
      {
        "transition" => { "id" => "#{status_id}" },
        # "fields": {
        #   "resolution": {
        #     # "name": "Fixed"
        #     "name": "Done"
        #   }
        # },
        "update" => {
          "comment" => [
            {
              "add" => {
                "body" => {
                  "type" => "doc",
                  "version" => 1,
                  "content" => [
                    {
                      "type" => "paragraph",
                      "content" => [
                        {
                          "text" => comment,
                          "type" => "text"
                        }
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    end
  end
end
