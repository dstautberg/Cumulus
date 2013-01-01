# OptionParser
# --scan	Starts or continues a scan of the files on the local computer.
# --rescan	Restarts a scan from scratch.
# --report	Generates a report of all duplicate files.
# --delete	Process the duplicate file report and deletes files marked for deletion that exist on this computer.

# Scan computer.  Retrieves the current computer's name in a deterministic way, and scans all drives attached to the computer, except for the usb drive that the script is on.  Saves the metadata about the files in a database (filename, path, computer name, file size, last modified time, MD5 hash).  Scan is performed in a reproducible manner (sorted disk, directory, and file names) so it can be restarted if it is aborted in the middle of a scan.

# Continue Scan.  Restarts a scan where it left off.

# Generate Duplicate File Report.  Uses saved metadata to look for duplicate files.  Files with the same name are listed, along with any files that have matching MD5 hashes.  I could write the output to a CSV file, with an extra "delete" column at the end that defaults to "N", and then pull it into a spreadsheet and edit as needed and export to CSV again when done.

# Delete Duplicate Files.  Processes the edited duplicate file report (in CSV format) and deletes any files located on the current computer whose delete column is Y.

require 'find'
require 'macaddr'
require 'sequel'

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

start = Time.now
puts start

computer_id = Mac.addr

# Create the metadata database if it doesn't exist.  If the schema needs to change during development, just delete the
# database file and the script will recreate the database with the new schema.

db = Sequel.sqlite("dup.db")
db.create_table?(:files) do
  String :computer_id
  String :filename
  String :directory
  Integer :size
  DateTime :last_modified
  String :hash
end

# Get a list of all drives attached to this computer.

require 'Win32API'
GetLogicalDriveStrings = Win32API.new("kernel32", "GetLogicalDriveStrings", ['L', 'P'], 'L')
buf = "\0" * 1024
len = GetLogicalDriveStrings.call(buf.length, buf)
drives = buf[0..len].split("\0")

skip_path = File.absolute_path(__FILE__).match /^.*:\//

# Start scanning the files on the drives.  First pass: save "shell" records for all files that exist.

drives.sort.each do |path|
  begin
    if File.absolute_path(path).start_with?(skip_path)
      puts "Skipping #{path}, which is the drive we are running on"
    else
      Find.find(path) do |f|
        if File.file?(f)
          directory, filename = File.split(f)
          rows = db[:files].where(:computer_id => computer_id, :filename => filename, :directory => directory).all
          if rows.empty?
            puts "Adding file info for #{f}"
            db[:files].insert(:computer_id => computer_id, :filename => filename, :directory => directory)
          end
        end
      end
    end
  rescue => e
    # This will catch errors for things like cd drives that have no disk in them
    puts "Error: #{e.inspect} on #{path}"
  end
end

# Second pass: Retrieve metadata for the files that don't have it yet

while true
  rows = db[:files].where(:computer_id => computer_id, :hash => nil).limit(100).all
  break if rows.empty?

  rows.each do |row|
    f = File.join(row[:directory], row[:filename])
    puts "Recording metadata for #{f}"
    row.update(:size => File.size(f), :last_modified => File.mtime(f), :hash => file_hash(f))
  end
end

finish = Time.now

puts finish
duration = finish - start
puts "Took #{duration} secs, #{duration/60} mins, #{duration/3600} hours"
# Note: An initial test on my desktop machine with 3 usb drives attached took about 6 mins

# Generate Duplicate File Report

# Hmm, I'm not sure what the sql would look like for this, or if it's even a good idea to try to do too much of it in sql.
# I guess I could start with a query of the whole database sorted by filename, but that would involved iterating over the entire database.
# I could do a group by on the filename with a having clause to limit it to count > 1?
# This would be the first pass: things with the exact same filename.
# Subsequent queries could be for things with the same size and hash, since they could be files that were copied and renamed.
