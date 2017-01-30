class MylistsController < ApplicationController
  def video_list

    puts Video.connection.inspect
    @videos = Video.all
  end
end
