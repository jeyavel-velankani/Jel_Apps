class MylistsController < ApplicationController
  def video_list
    @videos = Video.all
  end
end
