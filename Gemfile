source 'https://rubygems.org'
source "https://user:We267RFF7BfwVt4LdqFA@privategems.herokuapp.com/"

# Specify your gem's dependencies in graph-backend.gemspec
gemspec

platform :ruby do
  gem 'thin'
end

group :development, :test do
  gem 'rack-client'
  gem 'uuid'
  gem 'rake'

  gem 'auth-backend', "~> 0.0.14"
  gem 'nokogiri'
  gem 'sqlite3'
  gem 'sinatra_warden', git: 'https://github.com/quarter-spiral/sinatra_warden.git'
  gem 'songkick-oauth2-provider', git: 'https://github.com/quarter-spiral/oauth2-provider.git'
end
