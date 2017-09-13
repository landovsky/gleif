task :gleif_worker => :environment do
  puts "Running gleif_worker"
  Rails.logger.info "Running gleif_worker rake task"
  begin
    DownloadManager.new.perform
  rescue Exception => msg
    puts msg
    MyLogger.logme("Gleif worker failed", msg, level: 'error')
  end
end
