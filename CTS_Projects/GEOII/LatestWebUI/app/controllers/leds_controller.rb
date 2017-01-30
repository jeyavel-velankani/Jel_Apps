class LedsController < ApplicationController
  layout "general"
	def index 
		leds = RtLedsInformation.find(:all)

		@leds_ar = []

  		if leds 
  			leds.each do |led|
  				id = led.channel_id
  				name = led.name
  				status_text = led.status_text
  				status_value = led.status_value

  				@leds_ar[id] = {:name => name, :status_text => status_text, :status_value => status_value}
  			end
  		end


  	end

  	def refresh
  		leds = RtLedsInformation.find(:all)

  		leds_ar = []

  		if leds 
  			leds.each do |led|
  				id = led.channel_id
  				name = led.name
  				status_text = led.status_text
  				status_value = led.status_value

  				leds_ar[id] = {:name => name, :status_text => status_text, :status_value => status_value}
  			end
  		end
  		render :json => leds_ar
  	end
end
           