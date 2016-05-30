require 'mechanize'
require 'tsort'
require 'rack'
require 'pry'

class MeetupGroupScraper

  def initialize
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
    @base_url = 'http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/'
    @url = URI 'http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/'
    @current_offset = 0
    @max_offset = 1
    @search_params = {offset: @current_offset, sort: 'join_date', desc: 1}
    params = Rack::Utils.build_query(@search_params)
    @search_url = @url + "?#{params}" 
    @all_member_results = []
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
        !link.href.nil?  && link.href.match(/http:\/\/www.meetup.com\/Small-Business-from-Concept-to-Startup\/members\/(\d+)/)
      end.map(&:href).uniq
      @current_offset += member_links.count
      fetch_member_info(member_links)
    end

    
  end
  # 
  # curl 'http://www.meetup.com/Small-Business-from-Concept-to-Startup/members/205604732/' -H 'Cookie: MEETUP_MEMBER="id=30428101&status=1&timestamp=1464103120&bs=0&tz=Asia%2FCalcutta&zip=meetup5&country=in&city=Chennai&state=&lat=13.09&lon=80.27&ql=false&s=af4345eb37115bc6ac98f89f6f4692acec0aea87&scope=ALL";'
  #

  def fetch_member_info(member_links)
    hash = {}
    member_links.each do |member|
      cookie = Mechanize::Cookie.new :domain => '.meetup.com', :name => "MEETUP_MEMBER", :value => "id=30428102&status=1&timestamp=1464103120&bs=0&ql=false&s=af4345eb37115bc6ac98f89f6f4692acec0aea87&scope=ALL", :path => '/'
      @agent.cookie_jar.clear!
      @agent.cookie_jar.add!(cookie)
      @member_page = @agent.get member
      @member_page.root.css('.D_memberProfileContentItem').each_with_index do |node, i|
        if i > 2
          question = node.children[1].children.to_html
          answer = node.children[3].children.to_html
          hash[node.children[1].children.to_html] = answer
        end
      end
      @all_member_results << hash
      p hash
      puts "\n ==== \n"
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