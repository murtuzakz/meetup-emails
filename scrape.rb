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
    @all_member_links = []
  end

  def finished?
    @current_offset >= @max_offset
  end

  ##
  # Prints the result of the search

  def print_result
    puts @all_member_links.uniq.count
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
      end.map(&:href)
      @all_member_links += member_links
      @current_offset += 20
    end

    print_result
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