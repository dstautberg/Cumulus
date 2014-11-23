# This is a proof-of-concept script for searching a directory tree of files and saving all the file metadata to
# a sqlite database.  It also includes a rate limiter to limit the amount of data it reads from disk per second.

require "find"
require "sequel"
require "digest"

db = Sequel.sqlite("dup.db")
db.drop_table :files
db.create_table(:files) do
  String :name
  String :directory
  Integer :size
  DateTime :last_modified
  String :hash
end

MAX_READ_RATE = 10000000 # bytes per second
READ_SLEEP_TIME = 0.1
MAX_READ_PER_LOOP = MAX_READ_RATE * READ_SLEEP_TIME

def file_hash(file)
  digest = Digest::SHA2.new
  File.open(file, 'rb') do |f|
    while buffer = f.read(MAX_READ_PER_LOOP)
      digest.update(buffer)
      sleep READ_SLEEP_TIME
    end
  end
  digest.hexdigest
end

count, start = 0, Time.now
last_output = start

puts start
Find.find("/").each do |f|
  if File.file?(f)
    data = {}
    data[:directory], data[:name] = File.split(f)
    data[:size] = File.size(f)
    data[:last_modified] = File.mtime(f)
    data[:hash] = file_hash(f)
    db[:files].insert(data)
    count += 1
    if Time.now - last_output > 1
      last_output = Time.now
      files_per_second = count.to_f / (Time.now - start).to_f
      print "Files: %d, DB Size: %0.1f KB, Files per sec: %0.1f\r" % [count, File.size("dup.db")/1024.0, files_per_second]
    end
  end
end
puts
puts Time.now
