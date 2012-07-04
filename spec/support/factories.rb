FactoryGirl.define do
  factory :default do
    sequence :name do |n|
      "category #{n}"
    end
  end

  factory :default_with_counter_cache do
    sequence :name do |n|
      "category #{n}"
    end
  end
end