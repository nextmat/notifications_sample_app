
# Set up a memoized statsd instance to use to send data to a
# locally running statsd instance.
#
# The Statsd class comes from statsd-ruby.
module SampleApp
  
  def self.statsd
    @statsd ||= Statsd.new 'localhost', 8125
  end
  
end

ActiveSupport::Notifications.subscribe /performance/ do |name, start, finish, id, payload|
  #binding.pry
  method = payload[:action] || :increment
  name = "request.#{payload[:measurement]}"
  SampleApp.statsd.__send__(method, name, (payload[:value] || 1))
end

ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args| 
  #binding.pry
  event = ActiveSupport::Notifications::Event.new(*args)
  controller = event.payload[:controller]
  action = event.payload[:action]
  format = event.payload[:format] || "all" 
  format = "all" if format == "*/*" 
  status = event.payload[:status]
  request_key = "#{controller}.#{action}.#{format}."
  [''].each do |key|
    ActiveSupport::Notifications.instrument :performance, :action => :timing, :measurement => "#{key}total_duration", :value => event.duration
    ActiveSupport::Notifications.instrument :performance, :action => :timing, :measurement => "#{key}db_time", :value => event.payload[:db_runtime]
    ActiveSupport::Notifications.instrument :performance, :action => :timing, :measurement => "#{key}view_time", :value => event.payload[:view_runtime]
    ActiveSupport::Notifications.instrument :performance, :measurement => "#{key}status.#{status}" 
  end
end