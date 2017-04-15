require_relative 'github_search_worker'

class GithubSearcher
  def initialize(arguments)
    @arguments = arguments
  end

  def run
    type = (arguments.delete('--issues') ? :issues : :code)

    q = arguments.shift
    usage if arguments.size != 0

    GithubSearchWorker.search(q, type) do |items|
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
end




