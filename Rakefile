# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

task :environment do
  Rollbar.configure do |config |
    puts "____UPDATE token in rakefile if you want to test"
    config.access_token = ''
  end
end
