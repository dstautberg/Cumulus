# OptionParser
# --scan	Starts or continues a scan of the files on the connected computer.
# --rescan	Restarts a scan from scratch.
# --report	Generates a report of all duplicate files.
# --delete	Process the duplicate file report and deletes files marked for deletion that exist on this computer.

# Scan computer.  Retrieves the current computer's name in a deterministic way, and scans all drives attached to the computer, except for the usb drive that the script is on.  Saves the metadata about the files in a database (filename, path, computer name, file size, last modified time, CRC or MD5 hash?).  Scan is performed in a reproducable manner (sorted disk, directory, and file names) so it can be restarted if it is aborted in the middle of a scan.

# Continue Scan.  Restarts a scan where it left off.

# Generate Duplicate File Report.  Uses saved metadata to look for duplicate files.  Files with the same name are listed, along with any files that have matching MD5 hashes.  I could write the output to a CSV file, with an extra "delete" column at the end that defaults to "N", and then pull it into a spreadsheet and edit as needed and export to CSV again when done.

# Delete Duplicate Files.  Processes the edited duplicate file report (in CSV format) and deletes any files located on the current computer whose delete column is Y.

require 'find'
require 'macaddr'

start = Time.now
puts start

puts Mac.addr

# Get a list of all drives attached to this computer.

require 'Win32API' 
GetLogicalDriveStrings = Win32API.new("kernel32", "GetLogicalDriveStrings", ['L', 'P'], 'L') 
buf = "\0" * 1024
len = GetLogicalDriveStrings.call(buf.length, buf) 
drives = buf[0..len].split("\0")

skip_path = File.absolute_path(__FILE__).match /^.*:\//

drives.sort.each do |path|
    begin
        if File.absolute_path(path).begins_with(skip_path)
            puts "Skipping #{path}, which is the drive we are running on"
        else
            # I'm not sure if it's possible to have Find.find go through the directory in a consistent manner.
            # Maybe the initial pass can just save the paths, and a separate thread/queue can fill in the metadata.
            # That way the Continue Scan use case can rebuild the file list, since that doesn't take too long, and let
            # the metadata thread just fill in what needs to be filled in.
            Find.find(path) do |f|
                puts f
                # Get metadata about the file (filename, path, computer name, file size, last modified time, CRC or MD5 hash?)
                # Save a record to the database
            end
        end
    rescue => e
        # This will catch errors for things like cd drives that have no disk in them
        puts "Error: #{e.inspect} on #{path}"
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
