require "date"

class Test
HOUR_QUARTERS = ['00', '15', '30', '45']

def ts_hours_till_now(last_ts_hour, current_ts_hour)
  regex = /
  (?<year>\d{4})
  (?<month>\d{2})
  (?<day>\d{2})
  (?<hour>\d{2})
  /x
  md = last_ts_hour.match(regex)
  if current_ts_hour
    md_endtime = current_ts_hour.match(regex)
    current_ts_hour = DateTime.new(md_endtime[:year].to_i, md_endtime[:month].to_i, md_endtime[:day].to_i, md_endtime[:hour].to_i)
  end

  last_ts_hour_date = DateTime.new(md[:year].to_i, md[:month].to_i, md[:day].to_i, md[:hour].to_i)
  current_date = current_ts_hour ? current_ts_hour : DateTime.now

  hour_step = (1.to_f)/24
  result = last_ts_hour_date.step(current_date, hour_step).map do |date|
    year = date.strftime "%Y"
    month = date.strftime "%m"
    day = date.strftime "%d"
    hour = date.strftime "%H"
    HOUR_QUARTERS.map { |quarter|
      "#{year}#{month}#{day}#{hour}#{quarter}"
    }
  end
  result = result.flatten
  result.select{|quarter| quarter >= last_ts_hour}
end

end

test = Test.new
x = test.ts_hours_till_now('201612160945', nil)
puts "XXXX -#{x.size}: #{x}"