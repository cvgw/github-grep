require 'cgi'
require 'json'
require 'faraday'

require_relative 'github_search_page_client'

class GithubSearchWorker
  def self.search(q, type, &block)
    new.search(q, type, &block)
  end

  def search(q, type, &block)
    per_page = 100
    page = 1

    loop do
      response = page(q, type, page, per_page)
      if page == 1
        $stderr.puts "Found #{response.fetch("total_count")}"
      else
        $stderr.puts "Page #{page}"
      end
      items = response.fetch('items')

      block.call(items)

      break if items.size < per_page
      page += 1
    end
  end

  private

  def page(q, type, page, per_page)
    client = GithubSearchPageClient.new(q: q, type: type, page: page, per_page: per_page, github_token: github_token)
    with_response_handling do
      client.page
    end
  end

  def github_token
    ENV['GITHUB_AUTH_TOKEN']
  end

  def with_response_handling
    response = yield

    unless response.success?
      retry_after = response.headers.fetch('Retry-After', nil)
      if retry_after
        sleep(retry_after.to_i)
        response = yield
      else
        raise "\n\nERROR Request failed, reply was: #{response.body}"
      end
    end

    headers = response.headers
    handle_rate_limiting(headers)

    JSON.parse(response.body)
  end

  def handle_rate_limiting(headers)
    calls_remaining = headers.fetch('x-ratelimit-remaining').to_i
    total_allowed_calls_for_interval = headers.fetch('x-ratelimit-limit').to_i
    puts total_allowed_calls_for_interval
    puts calls_remaining

    if calls_remaining <= 1
      sleep(60)
    end
  end
end
