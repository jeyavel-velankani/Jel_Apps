module UdpCmdHelper  

  # Send a UDP message containing a command and request ID
  def udp_send_cmd(cmd,req_id)
    sock = UDPSocket.new
    data =[cmd].pack "C"
    data +=  [req_id].pack "I"
    sock.send(data, 0, REQUEST_REPLY_IP_ADDR, REQUEST_UDP_PORT)
    sock.close
  end

  # Send a UDP message containing only a request ID
  def udp_send_reqid(req_id)
    sock = UDPSocket.new
    data =""
    data +=  [rqid].pack "I"
    sock.send(data, 0, REQUEST_REPLY_IP_ADDR, REQUEST_UDP_PORT)
    sock.close
   end

  def udp_recv_data
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
  
end