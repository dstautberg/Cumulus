module FileReceiver
  def post_init
     streamer = EventMachine::FileStreamer.new(self, '/tmp/bigfile.tar')
     streamer.callback{
       # file was sent successfully
       close_connection_after_writing
     }
   end
end
