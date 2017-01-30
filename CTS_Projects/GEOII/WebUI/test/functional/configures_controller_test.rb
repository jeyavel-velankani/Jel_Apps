require 'test_helper'

class ConfiguresControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:configures)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create configure" do
    assert_difference('Configure.count') do
      post :create, :configure => { }
    end

    assert_redirected_to configure_path(assigns(:configure))
  end

  test "should show configure" do
    get :show, :id => configures(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => configures(:one).to_param
    assert_response :success
  end

  test "should update configure" do
    put :update, :id => configures(:one).to_param, :configure => { }
    assert_redirected_to configure_path(assigns(:configure))
  end

  test "should destroy configure" do
    assert_difference('Configure.count', -1) do
      delete :destroy, :id => configures(:one).to_param
    end

    assert_redirected_to configures_path
  end
end
