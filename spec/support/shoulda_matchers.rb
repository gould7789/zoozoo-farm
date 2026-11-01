# shoulda-matchers 를 RSpec·Rails 에 붙이는 설정
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
