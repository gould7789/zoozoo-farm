require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ZooKeeper
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # 기본 로케일은 한국어
    config.i18n.default_locale = :ko

    # 첨부는 Rails 를 거쳐 배포한다(proxy) — 기본값인 redirect 는 CSP 에 막힌다.
    # 뷰마다 헬퍼를 고르면 한 곳만 빠뜨려도 그 화면이 깨진다 (notes/infra.md)
    config.active_storage.resolve_model_to_route = :rails_storage_proxy

    # 기본키는 UUID v4 — 순번 정수 ID 가 URL 에 노출되는 IDOR 위험을 막는다.
    # 실제 생성은 DB 의 gen_random_uuid()(= v4) 가 맡는다
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # 쓰는 사람과 운영 거점이 한국이라 KST 로 고정한다 (notes/infra.md)
    config.time_zone = "Asia/Seoul"

    # config.eager_load_paths << Rails.root.join("extras")
  end
end
