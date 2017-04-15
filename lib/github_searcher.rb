require 'cgi'
require 'json'
require 'faraday'

class GithubSearcher
  def initialize(arguments)
    @arguments = arguments
  end

  def run
    type = (arguments.delete('--issues') ? :issues : :code)

    q = arguments.shift
    usage if arguments.size != 0

    search(q, type) do |items|
      if type == :issues
        puts issue_items_to_lines(items)
      else
        puts code_items_to_lines(items)
      end
    end
  end

  private

  attr_reader :arguments

  def usage
    puts <<-TEXT.gsub(/^    /, "")
      Setup
      -----
      # create a new token at https://github.com/settings/tokens/new with repo access
      git config github.token NEW_TOKEN --local

      Usage
      -----
      #{$0} 'something to search for'
    TEXT
    exit 1
  end

  def code_items_to_lines(items)
    items.flat_map do |item|
      file = item.fetch('repository').fetch('name') + ":" + item.fetch('path')
      lines(item).map { |l| "#{file}: #{l}" }
    end
  end

  def issue_items_to_lines(items)
    items.flat_map do |item|
      number = item.fetch("number")
      lines(item).map { |l| "##{number}: #{l}" }
    end
  end

  def lines(item)
    item.fetch("text_matches").flat_map { |match| match.fetch('fragment').split("\n") }
  end

  def search(q, type)
    per_page = 100
    page = 1
    pages_until_sleep = 4

    loop do
      with_rate_limiting do
        if pages_until_sleep == 0
          sleep(30)
          pages_until_sleep = 4
          next
        end
        response = page(q, type, page, per_page)
        if page == 1
          $stderr.puts "Found #{response.fetch("total_count")}"
        else
          $stderr.puts "Page #{page}"
        end

        items = response.fetch('items')
        yield items

        break if items.size < per_page
        page += 1
        pages_until_sleep -= 1
      end
    end
  end

  def page(q, type, page, per_page)
    github_token = `git config github.token`.strip
    usage if github_token.empty?
    host = 'https://api.github.com'
    path = "/search/#{type}?per_page=#{per_page}&page=#{page}&q=#{CGI.escape(q)}"

    connection = Faraday.new(host) do |conn|
      conn.request :url_encoded # form-encode POST params
      conn.adapter Faraday.default_adapter
      # conn.response :logger
    end
    response = connection.get path do |req|
      req.headers['Authorization'] = "token #{github_token}"
      req.headers['Accept'] = 'application/vnd.github.v3.text-match+json'
    end
    response

    headers = response.headers
    # puts headers

    unless response.success?
      raise "\n\nERROR Request failed, reply was: #{response.body}"
    end

    calls_remaining = headers.fetch('x-ratelimit-remaining').to_i
    total_allowed_calls_for_interval = headers.fetch('x-ratelimit-limit').to_i
    puts total_allowed_calls_for_interval
    puts calls_remaining

    if calls_remaining <= 1
      sleep(60)
    end

    JSON.parse(response.body)
  end

  def with_rate_limiting
    yield
    # sleep(10)
  end
end
