class RefreshExternalAppsJob < ApplicationJob
  def perform
    return if Rails.env.development? && !ENV["REFRESH_EXTERNAL_APPS"]
    App.find_each do |app|
      next unless app.has_recent_activity?
      app.refresh_external_app if app.ready?
    end
  end
end
