require 'test_helper'

class EnumToValuesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enum_to_values)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enum_to_value" do
    assert_difference('EnumToValue.count') do
      post :create, :enum_to_value => { }
    end

    assert_redirected_to enum_to_value_path(assigns(:enum_to_value))
  end

  test "should show enum_to_value" do
    get :show, :id => enum_to_values(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => enum_to_values(:one).to_param
    assert_response :success
  end

  test "should update enum_to_value" do
    put :update, :id => enum_to_values(:one).to_param, :enum_to_value => { }
    assert_redirected_to enum_to_value_path(assigns(:enum_to_value))
  end

  test "should destroy enum_to_value" do
    assert_difference('EnumToValue.count', -1) do
      delete :destroy, :id => enum_to_values(:one).to_param
    end

    assert_redirected_to enum_to_values_path
  end
end
