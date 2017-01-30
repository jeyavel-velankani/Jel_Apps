require 'test_helper'

class EnumParamsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enum_params)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enum_param" do
    assert_difference('EnumParam.count') do
      post :create, :enum_param => { }
    end

    assert_redirected_to enum_param_path(assigns(:enum_param))
  end

  test "should show enum_param" do
    get :show, :id => enum_params(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => enum_params(:one).to_param
    assert_response :success
  end

  test "should update enum_param" do
    put :update, :id => enum_params(:one).to_param, :enum_param => { }
    assert_redirected_to enum_param_path(assigns(:enum_param))
  end

  test "should destroy enum_param" do
    assert_difference('EnumParam.count', -1) do
      delete :destroy, :id => enum_params(:one).to_param
    end

    assert_redirected_to enum_params_path
  end
end
