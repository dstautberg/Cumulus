require 'java'
require 'socket'
require 'lib/hazelcast-1.9.1-SNAPSHOT.jar'

java_import com.hazelcast.core.Hazelcast
java_import java.util.concurrent.TimeUnit
java_import java.util.HashMap
java_import java.io.FileInputStream
java_import java.io.FileOutputStream
java_import java.security.MessageDigest
java_import java.lang.String
java_import java.math.BigInteger

class FileTransferHandler
    def initialize
        puts "FileTransferHandler: Starting"
        @request_queue_name = "file_request_#{Socket.gethostname.downcase}"
        @response_queue_name = "file_response_#{Socket.gethostname.downcase}"
        Thread.new { monitor_request_queue }
        Thread.new { monitor_response_queue }
    end

    def request_file(filepath, request_queue_name)
        # Create message and put it on the appropriate request queue
        request = HashMap.new
        request.put('filepath', filepath)
        request.put('respond_to', @response_queue_name)
        puts "[#{Time.now}] Sending request to #{request_queue_name} for file #{filepath}"
        Hazelcast.getQueue(request_queue_name).put(request)
    end

    private

    def monitor_request_queue
        puts "FileTransferHandler: Starting thread to monitor #{@request_queue_name}"
        buffer = Java::byte[1000000].new
        response = HashMap.new
        request_queue = Hazelcast.getQueue(@request_queue_name)
        while true
            begin
                request = request_queue.take
                puts "[#{Time.now}] Got request for '#{request.get('filepath')}'"

                # Send a start_file_send response first
                response.clear
                response.put('start_file_send', true)
                response.put('filepath', request.get('filepath'))
                response_queue = Hazelcast.getQueue(request.get('respond_to'))
                response_queue.put(response)

                # Now send the data
                input = FileInputStream.new(request.get('filepath'))
                digest = MessageDigest.getInstance("MD5")
                while true do
                    size = input.read(buffer)
                    break if size == -1
                    response.clear
                    response.put('filepath', request.get('filepath'))
                    response.put('data', buffer)
                    response.put('data_size', size)
                    puts "[#{Time.now}] Sending file chunk"
                    success = false
                    until success
                        begin
                            response_queue.put(response)
                            success = true
                        rescue java.lang.RuntimeException => e
                            puts "Error: #{e}"
                            sleep 1
                            success = false
                        end
                    end
                    if size == buffer.length
                        digest.update(buffer)
                    else
                        digest.update(buffer[0...size])
                    end
                end
                input.close
                
                # Send an "end_file_send" message that includes the MD5 hash
                response.clear
                response.put('end_file_send', true)
                response.put('filepath', request.get('filepath'))
                response.put('md5', String.format("%1$032X", BigInteger.new(1, digest.digest)))
                response.put('request_queue_name', @request_queue_name)
                puts "[#{Time.now}] Sending MD5 digest for file"
                response_queue.put(response)
            rescue Exception => e
               puts "[#{Time.now}] Error processing message: #{e}"
               puts e.backtrace
            end
        end
    rescue Exception => e
        puts "Error: #{e}"
        puts e.backtrace
    end

    def monitor_response_queue
        puts "FileTransferHandler: Starting thread to monitor #{@response_queue_name}"
        backup_repositories = ['backups'] # where should this go?
        response_queue = Hazelcast.getQueue(@response_queue_name)
        while true do
          begin
            response = response_queue.take
            backup_file_path = File.join(backup_repositories[0], response.get('filepath').gsub(":",""))
            dirname = File.dirname(backup_file_path)
            java.io.File.new(dirname).mkdirs

            if response.get('start_file_send')
              puts "[#{Time.now}] Truncating file"
              FileOutputStream.new(backup_file_path).close # truncate the file
            elsif response.get('end_file_send')
              md5 = response.get('md5')
              puts "[#{Time.now}] MD5: #{md5}"
              if matching_md5(backup_file_path, md5)
                puts "[#{Time.now}] MD5 is valid"
              else
                puts "[#{Time.now}] MD5 is invalid, resending file request"
              end
            else
              data_size = response.get('data_size')
              data = response.get('data')
              data = data[0...data_size]
              puts "[#{Time.now}] Appending #{data_size} bytes to file #{backup_file_path}"
              output = FileOutputStream.new(backup_file_path, true)
              output.write(data)
              output.close
            end
          rescue Exception => e
            puts "[#{Time.now}] Error processing message: #{e}"
            puts e.backtrace
          end
        end
    rescue Exception => e
        puts "Error: #{e}"
        puts e.backtrace
    end

    def matching_md5(backup_file_path, md5)
        buffer = Java::byte[1000000].new
        input = FileInputStream.new(backup_file_path)
        digest = MessageDigest.getInstance("MD5")
        while true do
            size = input.read(buffer)
            break if size == -1
            if size == buffer.length
                digest.update(buffer)
            else
                digest.update(buffer[0...size])
            end
        end
        input.close
        return md5 == String.format("%1$032X", BigInteger.new(1, digest.digest))
    end

end
