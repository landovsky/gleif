Rollbar.configure do |config|
  config.access_token = 'ab536f5693f742dd898d05bda228ff08'

  config.enabled = false if %w(development test).include? Rails.env

  config.use_delayed_job if %w(nic).include? Rails.env

  config.exception_level_filters['ActionController::RoutingError'] = 'ignore'

  config.environment = ENV['ROLLBAR_ENV'] || Rails.env
end
