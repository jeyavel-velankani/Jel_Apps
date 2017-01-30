require 'test_helper'

class LogRequestsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:log_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create log_request" do
    assert_difference('LogRequest.count') do
      post :create, :log_request => { }
    end

    assert_redirected_to log_request_path(assigns(:log_request))
  end

  test "should show log_request" do
    get :show, :id => log_requests(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => log_requests(:one).to_param
    assert_response :success
  end

  test "should update log_request" do
    put :update, :id => log_requests(:one).to_param, :log_request => { }
    assert_redirected_to log_request_path(assigns(:log_request))
  end

  test "should destroy log_request" do
    assert_difference('LogRequest.count', -1) do
      delete :destroy, :id => log_requests(:one).to_param
    end

    assert_redirected_to log_requests_path
  end
end
