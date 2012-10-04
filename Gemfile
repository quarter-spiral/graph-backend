source 'https://rubygems.org'

# Specify your gem's dependencies in graph-backend.gemspec
gemspec

platform :ruby do
  gem 'thin'
end

group :development, :test do
  gem 'rack-client'
  gem 'uuid'
  gem 'rake'

  gem 'auth-backend', "~> 0.0.3"
  gem 'sqlite3'
  gem 'sinatra_warden', git: 'https://github.com/quarter-spiral/sinatra_warden.git'
  gem 'songkick-oauth2-provider', git: 'https://github.com/quarter-spiral/oauth2-provider.git'
end
