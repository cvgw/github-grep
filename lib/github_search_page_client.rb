class GithubSearchPageClient
  def initialize(q:, type:, page:, per_page:, github_token:)
    @q = q
    @type = type
    @page_number = page
    @per_page = per_page
    @github_token = github_token
  end

  def page
    usage if github_token.empty?
    host = 'https://api.github.com'
    path = "/search/#{type}?per_page=#{per_page}&page=#{page_number}&q=#{CGI.escape(q)}"

    connection = Faraday.new(host) do |conn|
      conn.request :url_encoded # form-encode POST params
      conn.adapter Faraday.default_adapter
      # conn.response :logger
    end
    request_page(connection, path, github_token)
  end

  private

  def request_page(connection, path, github_token)
    connection.get path do |req|
      req.headers['Authorization'] = "token #{github_token}"
      req.headers['Accept'] = 'application/vnd.github.v3.text-match+json'
    end
  end

  attr_reader :q, :type, :page_number, :per_page, :github_token
end
