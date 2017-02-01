def greet(hour_of_clock)
  hour_of_clock = 21
  puts 'hour_of_clock',hour_of_clock
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
puts greet(Time.new.hour)