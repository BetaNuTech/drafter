# Awesome print (optional)
require 'awesome_print'
AwesomePrint.irb!

#IRB.conf[:USE_AUTOCOMPLETE] = false
#IRB.conf[:USE_COLORIZE] = false
IRB.conf[:HISTORY_FILE] = ENV['IRB_HISTFILE']
IRB.conf[:SAVE_HISTORY] = 1000

# Log to STDOUT (optional)
if ENV['RAILS_ENV']
  IRB.conf[:IRB_RC] = Proc.new do
    logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger = logger
  end
end

class Object
  def interesting_methods
    case self.class
    when Class
      self.public_methods.sort - Object.public_methods
    when Module
      self.public_methods.sort - Module.public_methods
    else
      self.public_methods.sort - Object.new.public_methods
    end
  end
end

def capture_exception(&block)
  block.call
rescue => exception
  exception
end

def time(&block)
  t0 = Time.now
  block.call
  puts Time.now - t0
end

def ri(*args)
  help(*args)
end
