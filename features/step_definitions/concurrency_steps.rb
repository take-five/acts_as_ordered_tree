# coding: utf-8

When /^I want to (.+?)(?: (\d+) times)?$/ do |step, n|
  n ||= 1
  @pending_steps ||= []

  n.to_i.times do
    @pending_steps << proc { step "I #{step}" }
  end
end

When /^I perform these actions simultaneously$/ do
  @pending_steps.map do |step|
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection(&step)
    end
  end.each(&:join)

  @pending_steps = []
end