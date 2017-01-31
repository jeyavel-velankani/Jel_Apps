require 'test_helper'

class RegularExpControllerTest < ActionController::TestCase
  test "should get regular" do
    get :regular
    assert_response :success
  end

end
