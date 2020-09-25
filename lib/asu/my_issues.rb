
module Asu
  class MyIssues
    # STATUS_CLOSED = '6' # This works for some
    STATUS_CLOSED = '51' # ... but this works for more; why???
    STATUS_CLOSED_HASH = {
      "self"=>"https://linuxacademy.atlassian.net/rest/api/2/status/6",
      "description"=>"The issue is considered finished, the resolution is correct. Issues which are closed can be reopened.",
      "iconUrl"=>"https://linuxacademy.atlassian.net/images/icons/statuses/closed.png",
      "name"=>"Closed",
      "id"=>"6",
      "statusCategory"=> {
        "self"=>"https://linuxacademy.atlassian.net/rest/api/2/statuscategory/3", "id"=>3, "key"=>"done", "colorName"=>"green", "name"=>"Done"
      }      
    }
    CLOSEABLE_STATUSES = ["Done", "Needs External QA", "Needs Internal QA", "QA Approved", "Released to Production", "Dev Complete", "Released to Staging", "Ready for QA", "Resolved", "In QA", "Pass", "In Staging", "Ready for Prod", "Prod Verified", "Shipped"]

    attr_reader :auth
    attr_reader :client
    attr_accessor :user_id
    attr_reader :sc
    attr_reader :my_doneish

    def initialize(user_id, ingore_prev_skips: false) # (auth)
      @auth = Auth.new
      @client = auth.client
      @user_id = user_id

      @non_skip_tickets = []
      @skip_tickets = []
      unless ingore_prev_skips
        File.open('log/errored_tickets.log', 'r') do |f|
          doc = f.read
          @skip_tickets = JSON.parse(doc).to_a if doc.to_s.length > 0
        end
      end

      @errored_tickets = []
      @sc = StatusChanger.new # (@auth)
    end
    
    def run(max_results: 1, verbose: false)
      puts "\n#{'*'*40}\n#{self.class.name}##{__method__}:\n#{'-'*40}\n"

      @issues_per_project = {} # ||= Hash.new(0)
      @statuses_per_project = {}

      @my_doneish = doneish(max_results: max_results)
      puts
      puts "@my_doneish:"
      pp @my_doneish; nil

      puts
      @summaries = issues_summaries(verbose: verbose) # (my_doneish)
      pp @summaries; nil

      puts
      @preview = preview_issues #(summaries)
      puts
      puts "PREVIEW:"
      pp @preview; nil

      puts
      puts "ISSUES per project:"
      pp @issues_per_project; nil

      puts
      puts "STATUSE per projectS:"
      pp @statuses_per_project; nil

      puts
      puts "PREVIEW:"
      pp @preview.each_pair.map {|k,v| [k, v.size]}
      puts "ISSUES per project:"
      pp @issues_per_project.each_pair.map {|k,v| [k, v.size]}
      puts "STATUSES per project:"
      pp @statuses_per_project.each_pair.map {|k,v| [k, v.size]}
      
      puts
      puts "CLOSING:"
      @closing_results = close_issues # (preview) # (@auth, my_doneish)
      pp @closing_results; nil

      attempted_ticket_keys = @preview[:closeable].map{|s| s[:key]}
      successful_ticket_keys = attempted_ticket_keys - @errored_tickets
      
      puts
      puts "@skip_tickets: #{@skip_tickets}"
      puts "@skip_tickets.size: #{@skip_tickets.size}"
      puts
      puts "@non_skip_tickets: #{@non_skip_tickets}"
      puts "@non_skip_tickets.size: #{@non_skip_tickets.size}"
      puts
      puts "attempted_ticket_keys: #{attempted_ticket_keys}"
      puts "attempted_ticket_keys.size: #{attempted_ticket_keys.size}"
      puts
      puts "@errored_tickets: #{@errored_tickets}"
      puts "@errored_tickets.size: #{@errored_tickets.size}"
      puts
      puts "successful_ticket_keys: #{successful_ticket_keys}"
      puts "successful_ticket_keys.size: #{successful_ticket_keys.size}"

      @skip_tickets = (@skip_tickets + @errored_tickets).uniq
      File.open('log/errored_tickets.log', 'w') {|f| f.write(@skip_tickets.to_json) }

      File.open('log/successful_ticket_keys.log', 'w') {|f| f.write(successful_ticket_keys.to_json) }
    end

    private

    def jql_doneish # (user_id) # , status_id)
      # skipped_issues_jql = "and issue not in ('#{@skip_tickets.join("','")}')" if @skip_tickets.size > 0

      skipped_issues_jql = ''

      <<-STRING
        status in ("#{CLOSEABLE_STATUSES.join('", "')}") AND assignee = #{@user_id} #{skipped_issues_jql} ORDER BY created ASC
      STRING
    end

    def doneish(max_results: nil) # status_id)
      jql = jql_doneish # (@user_id)
      options = {}
      options[:max_results] = max_results if max_results

      # jql(client, jql, options = { fields: nil, start_at: nil, max_results: nil, expand: nil, validate_query: true })

      JIRA::Resource::Issue.jql(@client, jql, options)
    end

    def issues_summaries(verbose: false) # (my_doneish)
      puts "\n#{'*'*40}\n#{self.class.name}##{__method__}:\n#{'-'*40}\n"

      @my_doneish.map do |issue|
        key = issue.attrs['key']
        unless ['CUSTOOL'].include?(key)
          @non_skip_tickets << key

          project = key.split('-').first
          # @issues_per_project[project] ||= Hash.new(0)
          # @issues_per_project[project] += 1
          @issues_per_project[project] ||= Hash.new(0)
          @issues_per_project[project][key] += 1

          status = {
              id: issue.status.attrs['id'],
              name: issue.status.attrs['name']
          }
          @statuses_per_project[project] ||= Hash.new(0)
          @statuses_per_project[project][status] += 1
          # @statuses_per_project[project] << status unless @statuses_per_project[project].include?(status)


          subs = issue.issuelinks.map do |sub_link|
            outwardIssue = sub_link.attrs['outwardIssue']
            if outwardIssue
              {
                id: outwardIssue['id'],
                key: outwardIssue['key'],
                status: {
                  id: outwardIssue['fields']['status']['id'],
                  name: outwardIssue['fields']['status']['name']
                },
                is_sub: outwardIssue['fields']['issuetype']['subtask']
              }
            else
              nil
            end
          end.compact.reject { |n| !n[:is_sub] }
          # subs = nil if subs.empty?

          summary = {
            key: key,
            url: "https://#{@auth.site}/browse/#{key}",
            status: status,
            subs_size: subs.size,
            subs: subs,
            # transitions: issue.transitions
          }
          summary.merge(issue: issue) if verbose
          summary   
        end     
      end.compact
    end

    def preview_issues # (summaries) # (my_doneish)
      puts "\n#{'*'*40}\n#{self.class.name}##{__method__}:\n#{'-'*40}\n"

      next_status_groups = {closeable: [], wait: []}
      @summaries.each do |summary|    
        closeable = case
        when ['BSV', 'CE'].include?(summary[:key].split('-').first) && summary[:status][:id] == '10002' # aka 'Done'
          puts "BSV/CE already done/closed! #{summary}"
          false
        when summary[:subs_size] == 0
          puts "Ok to CLOSE! #{summary}"
          true
        else summary[:subs_size] > 0
          subs = summary[:subs]
          puts "** Check! ** #{summary}"
          subs_closed = subs_closed?(subs)
        
          if subs_closed.all?
            puts "  All subs are closed! #{subs} (subs_closed: #{subs_closed})" 
            true
          else
            puts "  Some subs NOT closed! subs: #{subs} subs_closed: #{subs_closed}"
            false
          end
        end
      
        puts " ... closeable: #{closeable} .. #{closeable ? 'CLOSE' : 'skip'}"
        # summary.merge!(closeable: closeable)
        next_status = if closeable
          :closeable
        else
           :wait
        end
        next_status_groups[next_status] << summary
    
        # https://community.atlassian.com/t5/Jira-questions/JIRA-How-to-change-issue-status-via-rest/qaq-p/528133
        # curl -D- -u admin:admin -X POST --data @/Users/BaBs/Desktop/test.json -H "Content-Type: application/json" http://localhost:8080/jira/rest/api/2/issue/JC-11/transitions?expand=transitions.fields
        # curl -D- -u <USER>:<PASS_or_token> -X POST --data '{"transition":{"id":"<TRANSITION_ID>"}}' -H "Content-Type: application/json" <JIRA_URL>:<JIRA_PORT>/rest/api/latest/issue/<JIRA_ISSUE>/transitions?expand=transitions.fields
    
    
        # "status"=>{"self"=>"https://linuxacademy.atlassian.net/rest/api/2/status/6", "description"=>"The issue is considered finished, the resolution is correct. Issues which are closed can be reopened.", "iconUrl"=>"https://linuxacademy.atlassian.net/images/icons/statuses/closed.png", "name"=>"Closed", "id"=>"6", "statusCategory"=>{"self"=>"https://linuxacademy.atlassian.net/rest/api/2/statuscategory/3", "id"=>3, "key"=>"done", "colorName"=>"green", "name"=>"Done"}}
    
    
        # data = nil
        # data = {
        #   "update": { "comment": [ { "add": { "body": "closing issue via drh script" } } ] },
        #   "transition": {"id": "6"} # aka 'Closed'
        # } if closeable

        # status_change_result = 

        # transition it to 'subs_closed' if subs_closed.all?
    
        # {
        #   closeable: closeable,
        #   summary: summary # ,
        #   # data: data,
        #   # status_change_result: status_change_result,
        #   # status: status_change_result&.code || '',
        #   # body: status_change_result&.body || ''
        # }
      end
      next_status_groups
    end

    def subs_closed?(subs)
      subs.map do |sub|
        key = sub[:key]
        project = key.split('-').first
        # @issues_per_project[project] ||= Hash.new(0)
        # @issues_per_project[project] += 1
        @issues_per_project[project] ||= Hash.new(0)
        @issues_per_project[project][key] += 1
        status = {
            id: sub[:status][:id],
            name: sub[:status][:name]
        }
        @statuses_per_project[project] ||= Hash.new(0)
        @statuses_per_project[project][status] += 1
        # @statuses_per_project[project] << status unless @statuses_per_project[project].include?(status)

        sub[:status][:id] == "6" && sub[:status][:name] == "Closed"
        # sub[:status][:name] == "Closed"
      end
    end

    def close_issues # (preview)
      puts "\n#{'*'*40}\n#{self.class.name}##{__method__}:\n#{'-'*40}\n"

      results = @preview[:closeable].map do |summary|
        ticket_key = summary[:key]
        # unless @skip_tickets.include?(ticket_key)
          comment = "closing issue via drh script"
          result = @sc.change(ticket_key, STATUS_CLOSED, comment)

          values = result&.values
          if !values || values.first[:response][:code] != "204"
            @errored_tickets << ticket_key
          end

          result
        # else
        #   nil
        # end
      end

      results
    end
  end
end
