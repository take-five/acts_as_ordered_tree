FactoryGirl.define do
  factory :default do
    sequence(:name) { |n| "category #{n}" }
  end

  factory :default_with_counter_cache do
    sequence(:name) { |n| "category #{n}" }
  end

  factory :default_with_callbacks do
    sequence(:name) { |n| "category #{n}" }
  end

  factory :scoped do
    sequence(:scope_type) { |n| "type_#{n}" }
    sequence(:name) { |n| "category #{n}" }
  end
end