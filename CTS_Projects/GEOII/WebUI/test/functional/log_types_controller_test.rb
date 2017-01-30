require 'test_helper'

class LogTypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:log_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create log_type" do
    assert_difference('LogType.count') do
      post :create, :log_type => { }
    end

    assert_redirected_to log_type_path(assigns(:log_type))
  end

  test "should show log_type" do
    get :show, :id => log_types(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => log_types(:one).to_param
    assert_response :success
  end

  test "should update log_type" do
    put :update, :id => log_types(:one).to_param, :log_type => { }
    assert_redirected_to log_type_path(assigns(:log_type))
  end

  test "should destroy log_type" do
    assert_difference('LogType.count', -1) do
      delete :destroy, :id => log_types(:one).to_param
    end

    assert_redirected_to log_types_path
  end
end
