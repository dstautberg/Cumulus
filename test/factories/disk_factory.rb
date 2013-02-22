FactoryGirl.define do |f|
  factory :disk do
    path "/media/usb1"
    free_space 1000000
    created_at { Time.now }
    updated_at { Time.now }
  end
end
