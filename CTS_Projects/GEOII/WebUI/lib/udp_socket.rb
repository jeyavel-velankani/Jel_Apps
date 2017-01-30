module UdpSocket
=begin
  def recv_rq_rp_udp (cmd, rqid)
    sock2 = UDPSocket.new
    require 'socket'
    addr = ['0.0.0.0', REPLY_UDP_PORT]  # host, port
    BasicSocket.do_not_reverse_lookup = true
    # Create socket and bind to address
    sock2 = UDPSocket.new
    sock2.bind(addr[0], addr[1])
    # data, addr = sock2.recvfrom(1024) # if this number is too low it will drop the larger packets and never give them to you
    timeout(10) do
    #sample byte format -- 1111(byte) - decimal(15)
    @data, addr = sock2.recvfrom(1024)
    end

    rescue Timeout::Error
    @data=nil

   return @data
  end
=end  
end