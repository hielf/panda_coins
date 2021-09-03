class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true


  def current_user
    token, options = ActionController::HttpAuthentication::Token.token_and_options(request)
    # Rails.logger.warn "request headers token: #{token}"
    # Rails.logger.warn "request headers options: #{options}"
    mobile = options.blank? ? nil : options[:mobile]
    user = mobile && User.find_by(mobile: mobile)
    if user && user.access_token.present? && ActiveSupport::SecurityUtils.secure_compare(user.access_token, token)
      @current_user = user
    else
      unauthenticated!
    end
  end
end
