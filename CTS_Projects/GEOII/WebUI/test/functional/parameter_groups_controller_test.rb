require 'test_helper'

class ParameterGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:parameter_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create parameter_group" do
    assert_difference('ParameterGroup.count') do
      post :create, :parameter_group => { }
    end

    assert_redirected_to parameter_group_path(assigns(:parameter_group))
  end

  test "should show parameter_group" do
    get :show, :id => parameter_groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => parameter_groups(:one).to_param
    assert_response :success
  end

  test "should update parameter_group" do
    put :update, :id => parameter_groups(:one).to_param, :parameter_group => { }
    assert_redirected_to parameter_group_path(assigns(:parameter_group))
  end

  test "should destroy parameter_group" do
    assert_difference('ParameterGroup.count', -1) do
      delete :destroy, :id => parameter_groups(:one).to_param
    end

    assert_redirected_to parameter_groups_path
  end
end
