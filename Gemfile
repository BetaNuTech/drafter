source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.3"

#gem 'attr_encrypted'
#gem 'kredis'
#gem 'secure_headers'
#gem 'sidekiq'
gem 'aasm'
gem 'audited'
gem 'awesome_print'
gem 'aws-sdk-s3'
gem 'aws-sdk-textract'
gem 'aws-sdk-sqs'
gem 'bcrypt'
gem 'bootsnap', require: false
gem 'bootstrap', '~> 5.1.3'
gem 'bundler'
gem 'colorize'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'devise'
gem 'dotenv-rails'
gem 'factory_bot_rails'
gem 'flipflop', github: 'Bellingham-DEV/flipflop'
gem 'foreman'
gem 'httparty'
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
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'after_commit_everywhere'
gem 'clockwork', github: 'Rykian/clockwork'
gem 'rubyzip'

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
