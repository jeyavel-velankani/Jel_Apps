require 'benchmark'
class WelcomeController < ApplicationController
  def index
    @name = Name1.last
    @job = Job.last
  	@date = Time.zone.now.to_date
  	@time_words = []
  	@time = Time.now.to_s.split(" ").second
  end

  def give_time
	puts Benchmark.measure{
	    @time = Time.now.to_s.split(" ").second
	    hour = @time.split(":").first
	    min = @time.split(":").second
	    second = @time.split(":").third
	    @time_words = []
	    @time_words << hour.to_i.humanize << min.to_i.humanize << second.to_i.humanize
    }
    render :partial => 'my_time'
  end

  def myhaml
  end

  def name_save
  end
end
