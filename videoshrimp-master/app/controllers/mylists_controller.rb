require 'welcomedog'
class MylistsController < ApplicationController
  def video_list
    @videos = Video.all
    md = Welcomedog::Greeting.new
    @greet = md.process(Time.now.hour)
  end
end
