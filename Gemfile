source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

#gem 'kredis'
#gem 'sidekiq'
gem 'aasm'
#gem 'attr_encrypted'
gem 'audited'
gem 'bcrypt'
gem 'bootsnap', require: false
gem 'bundler'
gem 'colorize'
gem 'devise'
gem 'dotenv-rails'
gem 'flipflop', github: 'Bellingham-DEV/flipflop'
gem 'image_processing'
gem 'importmap-rails'
gem 'jbuilder'
gem 'net-imap', require: false
gem 'net-pop', require: false
gem 'net-smtp', require: false
gem 'pg'
gem 'pg_search'
gem 'puma', '~> 5.0'
gem 'pundit'
gem 'rails'
gem 'redis'
gem 'sassc-rails'
#gem 'secure_headers'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'foreman'
gem 'bootstrap', '~> 5.1.3'
gem 'awesome_print'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'daemons'
gem 'factory_bot_rails'
gem 'aws-sdk-s3'
gem 'httparty'
gem 'ruby-vips'

group :development do
  gem 'web-console'
  gem 'stackprof'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  # gem "spring"
  gem 'letter_opener'
  gem 'letter_opener_web'
  gem 'annotate'
  gem 'active_record_query_trace'
end


group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'pry-doc'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
  gem 'byebug'
  gem 'bundler-audit'
  gem 'faker'
end

group :test do
  gem 'rspec'
  gem 'warden-rspec-rails'
  gem 'capybara'
  gem 'guard-rspec'
  gem 'guard-rake'
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'rspec_junit_formatter'
  gem 'action-cable-testing'
end
