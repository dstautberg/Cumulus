Factory.define :disk do |f|
  f.path "/media/usb1"
  f.free_space 1000000
  f.created_at { Time.now }
  f.updated_at { Time.now }
end
