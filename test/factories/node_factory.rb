Factory.define :node do |f|
  f.sequence(:name) {|n| "Node #{n}"}
  f.ip "127.0.0.1"
  f.checked_in_at {Time.now - 10}
  f.created_at {Time.now}
  f.updated_at {Time.now}
end
