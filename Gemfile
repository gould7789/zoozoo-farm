source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4"
gem "dotenv-rails", groups: [ :development, :test ]
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.7"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Excel(.xlsx) 생성 — 열 폭·정렬·서식을 다룬다 (.claude/rules/notes/xlsx-export.md)
gem "caxlsx"
gem "caxlsx_rails" # xlsx MIME 타입을 등록해 send_data 로 내보낼 수 있게 한다

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Rails.cache 의 DB 백엔드. rate_limit 이 increment 의 반환값으로 판정하므로 필수다
gem "solid_cache"
# solid_queue / solid_cable 은 넣지 않는다 — 근거는 .claude/rules/notes/infra.md.
# 필요해지는 시점에 gem 과 마이그레이션을 더한다.

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 2.2"
# image_processing 2.0 이 ruby-vips 를 런타임 의존에서 빼서 직접 적어준다.
# 없으면 Active Storage 초기화가 LoadError 로 떨어진다 (docs/oss-candidates.md).
gem "ruby-vips", "~> 2.3", require: false
# S3 프로토콜 클라이언트 — AWS 가 아니라 Supabase Storage 에 붙으려고 쓴다.
# Active Storage 가 S3 서비스를 만드는 시점에 읽으므로 require: false.
gem "aws-sdk-s3", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec testing framework for Rails [https://github.com/rspec/rspec-rails]
  gem "rspec-rails"

  # Test data factory [https://github.com/thoughtbot/factory_bot_rails]
  gem "factory_bot_rails"

  # Fake data generator [https://github.com/faker-ruby/faker]
  gem "faker"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Concise matchers for RSpec [https://github.com/thoughtbot/shoulda-matchers]
  gem "shoulda-matchers"
end
