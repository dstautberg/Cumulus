class FileSender
  def initialize(file_path, send_to_ip, send_to_port)
    @file_path = file_path
    @send_to_ip = send_to_ip
    @send_to_port = send_to_port
    AppLogger.debug "#{self.class.to_s}: initialize complete"
  end

  def start
    AppLogger.debug "#{self.class.to_s}: starting thread"
    @thread = Thread.new { send_data }
    AppLogger.debug "#{self.class.to_s}: started thread"
  end

  def stop
    @stop = true
    AppLogger.debug "#{self.class.to_s}: sent stop signal"
  end

  def alive?
    @thread.alive?
  end

  def send_data
    AppLogger.debug "#{self.class.to_s}: send_data"
    open(@file_path, "rb") do |f|
      AppLogger.debug "#{self.class.to_s}: opened file #{@file_path}"
      socket = TCPSocket.new(@send_to_ip, @send_to_port)
      AppLogger.debug "#{self.class.to_s}: connected"
      while !@stop do
        data = f.read(1000)
        break if (data.nil? or data.size <= 0)
        AppLogger.debug "#{self.class.to_s}: read #{data.size} bytes from file"
        socket.send(data, 0)
        AppLogger.debug "#{self.class.to_s}: sent data"
      end
      AppLogger.debug "#{self.class.to_s}: done looping"
      socket.close
      AppLogger.debug "#{self.class.to_s}: socket closed"
    end
  rescue Exception => e
    AppLogger.error e
  end
end
