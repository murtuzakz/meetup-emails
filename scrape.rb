# ruby scrape.rb http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/ 30428102 1464103120 af4345eb37115bc6ac98f89f6f4692acec0aea87
require 'mechanize'
require 'tsort'
require 'rack'
require 'pry'
require 'csv'

class MeetupGroupScraper

  def initialize
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @base_url = ARGV[0]
    @url = URI @base_url
    @current_offset = 0
    @max_offset = 1
    @search_params = {offset: @current_offset, sort: 'join_date', desc: 1}
    params = Rack::Utils.build_query(@search_params)
    @search_url = @url + "?#{params}" 
    @header_created = false
  end

  def finished?
    @current_offset >= @max_offset
  end

  ##
  # Entry point

  def run
    while !finished? do
      search
      next_links = @page.links.select do |link| 
        !link.href.nil?  && link.href.index(@base_url + "?offset=") == 0
      end
      offsets = next_links.map do |a|
        !a.href.nil? && a.href.split(@base_url + "?offset=")[1].split("&").first.to_i
      end
      @max_offset = offsets.max
      member_links = @page.links.select do |link|
        !link.href.nil?  && link.href.match(/#{ARGV[0]}(\d+)/) && link.text.length > 0 && link.dom_class == "memName"
      end.map do |link|
        {href: link.href, name: link.text}
      end.uniq do |a|
        a[:href]
      end
      @current_offset += member_links.count
      fetch_member_info(member_links)
    end
  end

  def fetch_member_info(member_links)
    member_results = []
    member_links.each do |member|
      cookie_set_up!
      hash = {}
      @member_page = @agent.get member[:href]
      hash[:ma_name] = member[:name]
      @member_page.root.css('.D_memberProfileContentItem').each_with_index do |node, i|
        if i > 2
          question = node.children[1].children.to_html
          next if question == "Networks"
          answer = node.children[3].children.to_html
          hash[node.children[1].children.to_html] = answer
        end
      end
      member_results << hash
      p hash
      puts "\n ==== \n"
    end
    write_to_csv(member_results)
  end
  
  def build_cookie_value
    "id=#{ARGV[1]}&status=1&timestamp=#{ARGV[2]}&bs=0&ql=false&s=#{ARGV[3]}&scope=ALL"
  end

  def cookie_set_up!
    cookie = Mechanize::Cookie.new :domain => '.meetup.com', :name => "MEETUP_MEMBER", :value => build_cookie_value, :path => '/'
    @agent.cookie_jar.clear!
    @agent.cookie_jar.add!(cookie)
  end

  def write_to_csv(results)
    CSV.open("results.csv", "ab") do |csv|
      unless @header_created
        csv << results.first.keys  
        @header_created = true
      else
      end
      results.each do |res|
        begin
          csv << res.values
        rescue Exception => e
          puts e.to_s
        end
      end
    end
  end

  def search
    @page = @agent.get search_url
  end

  def search_url
    @search_params = {offset: @current_offset, sort: 'join_date', desc: 1}
    params = Rack::Utils.build_query(@search_params)
    @url + "?#{params}" 
  end
end

MeetupGroupScraper.new.run