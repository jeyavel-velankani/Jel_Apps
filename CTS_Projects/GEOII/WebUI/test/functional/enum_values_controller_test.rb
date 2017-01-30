require 'test_helper'

class EnumValuesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enum_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enum_value" do
    assert_difference('EnumValue.count') do
      post :create, :enum_value => { }
    end

    assert_redirected_to enum_value_path(assigns(:enum_value))
  end

  test "should show enum_value" do
    get :show, :id => enum_values(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => enum_values(:one).to_param
    assert_response :success
  end

  test "should update enum_value" do
    put :update, :id => enum_values(:one).to_param, :enum_value => { }
    assert_redirected_to enum_value_path(assigns(:enum_value))
  end

  test "should destroy enum_value" do
    assert_difference('EnumValue.count', -1) do
      delete :destroy, :id => enum_values(:one).to_param
    end

    assert_redirected_to enum_values_path
  end
end
