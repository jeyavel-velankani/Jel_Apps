require 'test_helper'

class EnumParametersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enum_parameters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enum_parameter" do
    assert_difference('EnumParameter.count') do
      post :create, :enum_parameter => { }
    end

    assert_redirected_to enum_parameter_path(assigns(:enum_parameter))
  end

  test "should show enum_parameter" do
    get :show, :id => enum_parameters(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => enum_parameters(:one).to_param
    assert_response :success
  end

  test "should update enum_parameter" do
    put :update, :id => enum_parameters(:one).to_param, :enum_parameter => { }
    assert_redirected_to enum_parameter_path(assigns(:enum_parameter))
  end

  test "should destroy enum_parameter" do
    assert_difference('EnumParameter.count', -1) do
      delete :destroy, :id => enum_parameters(:one).to_param
    end

    assert_redirected_to enum_parameters_path
  end
end
