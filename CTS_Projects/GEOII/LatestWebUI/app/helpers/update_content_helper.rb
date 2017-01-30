module UpdateContentHelper
  
  def updatevalues(result_array)
    i=0
    while i < result_array.length
      @paramvalues = result_array[i].split(/_/)
      @paramtype = @paramvalues[0]
      @paramid = @paramvalues[1]
      if @paramtype == 'enum'
        begin   
          @paramval = result_array[i].split(/=/)
          @selectedval = @paramval[1]
          EnumParameter.enum_update_group(@selectedval,@paramid)
        rescue  => e
          puts "exception caught in function"
          # session[:error]="error while saving"
          return 1
        end
      end
      
      if @paramtype == 'string'
        begin
          @paramval1 = result_array[i].split(/=/)
          @selectedval = @paramval1[1]
          StringParameter.string_update_group(@selectedval,@paramid)
        rescue => e
          puts e   
          #session[:error]="error while saving"
          session[:flag_val] = 1
          logger.error("Message for the log file #{e.message}")
          return 1
        end
      end
      
      if @paramtype == 'int'
        begin
          @paramval2 = result_array[i].split(/=/)
          @selectedval = @paramval2[1]
          IntegerParameter.Integer_update_group(@selectedval,@paramid)
        rescue => e
          puts e   
          #  session[:error]= "Problem while saving"
          session[:flag_val] = 1 
          logger.error("Message for the log file #{e.message}")
          return 1
        end
      end
      
      if @paramtype == 'byte'
        begin
          @paramval2 = result_array[i].split(/=/)
          @selectedval = @paramval2[1]
          ByteArrayParameter.Byte_update_group(@selectedval,@paramid)
        rescue => e
          puts e   
          #   session[:error]= "Problem while saving"
          session[:flag_val] = 1 
          logger.error("Message for the log file #{e.message}")
          return 1
        end
      end
      i = i + 1
    end
    return 0 
  end
  
end
