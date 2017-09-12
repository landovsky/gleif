module MyLogger
  def self.logme(topic = '', msg = '', options = {})
    level = options[:level] ? options[:level] : 'debug'
    time = Time.new.localtime
    begin
      options = remove_passwords(options).except(:level)
    rescue => e
      MyLogger.logme('ERROR', 'remove_passwords', error: e, level: 'error')
      options = options.except(:level)
    end
    content = "#{topic}: #{msg}: #{remove_passwords(options).except(:level)} | #{caller[0]} / #{caller[1]}"
    Rails.logger.send(level, "#{time} MYLOGGER (#{level}) #{content}")
    Rollbar.log(rollbar_level(level), content) unless level == 'unknown'
  end

  private

  def self.remove_passwords(options)
    options.keys.each do |key|
      next if options[key].class != Hash
      keys = options[key].keys.select { |key| key.to_s.match(/password/) }
      keys.each { |k| options[key][k] = 'removed' }
    end
    options
  end

  def self.rollbar_level(level)
    levels = {
      'warn' => 'warning',
      'debug' => 'debug',
      'info' => 'info',
      'error' => 'error',
      'fatal' => 'critical'
    }
    levels[level]
  end
end
