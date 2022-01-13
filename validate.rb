$VERBOSE = nil

def cost_array()
    calculator = BillingCalculator.new(nil)
    cf_token = CFWrapper.paas_token

    BillingCalculator.aggregate_cost(cf_token)
end

def reset_metrics
  Prometheus::Client.registry.metrics.each do |m|
    Prometheus::Client.registry.unregister(m.name)
  end
end

puts "Testing old billing API..."
require './billing.rb'

time_old_0 = Time.now
cost_array_old = cost_array
time_old_1 = Time.now

reset_metrics

puts "Testing new billing API..."
require './billing_new.rb'

time_new_0 = Time.now
cost_array_new = cost_array
time_new_1 = Time.now

if cost_array_old == cost_array_new
  puts "Costs are equal"
else
  puts "Costs are not equal"
end

puts "Old duration: #{(time_old_1 - time_old_0)}s"
puts "New duration: #{(time_new_1 - time_new_0)}s"
