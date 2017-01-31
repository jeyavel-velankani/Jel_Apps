class ApiController < ApplicationController

  rescue_from StandardError do |e|
    error_response = { message: e.message }
    render json: error_response
  end
end