name = "github-grep"

Gem::Specification.new name, '0.0.0' do |s|
  s.summary = "Makes github search grep and pipeable"
  s.authors = ["Cole Wippern"]
  s.email = "cgwippern@gmail.com"
  s.homepage = "https://github.com/cvgw/#{name}"
  s.license = "MIT"
  s.required_ruby_version = '>= 2.0.0'

  s.executables = ['github-grep']

  s.add_runtime_dependency "json"
  s.add_runtime_dependency 'faraday'

  s.add_development_dependency "rake"
  s.add_development_dependency "bump"
end
