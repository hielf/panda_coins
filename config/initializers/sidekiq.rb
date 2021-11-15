Sidekiq.configure_server do |config|
  config.redis = { url: "#{Rails.application.config_for(:redis)["market"]["url"]}#{Rails.application.config_for(:redis)["market"]["db"]}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "#{Rails.application.config_for(:redis)["market"]["url"]}#{Rails.application.config_for(:redis)["market"]["db"]}" }
end
