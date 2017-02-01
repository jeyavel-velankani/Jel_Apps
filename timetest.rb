module Welcomedog
  class Greeting
    def process(hour_of_clock)
      greet(hour_of_clock)
    end

    private def greet(hour_of_clock)
      if hour_of_clock >= 6 && hour_of_clock <= 11
        "Good Morning"
      elsif hour_of_clock >= 12 && hour_of_clock <= 16
        "Good Afternoon"
      elsif hour_of_clock >= 17 && hour_of_clock <= 20
        "Good Evening"
      else
        "Good Night"
      end
    end
 end
end
a = Welcomedog::Greeting.new
puts a.process(Time.now.hour) 

