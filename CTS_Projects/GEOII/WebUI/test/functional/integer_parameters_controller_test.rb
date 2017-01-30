require 'test_helper'

class IntegerParametersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:integer_parameters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create integer_parameter" do
    assert_difference('IntegerParameter.count') do
      post :create, :integer_parameter => { }
    end

    assert_redirected_to integer_parameter_path(assigns(:integer_parameter))
  end

  test "should show integer_parameter" do
    get :show, :id => integer_parameters(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => integer_parameters(:one).to_param
    assert_response :success
  end

  test "should update integer_parameter" do
    put :update, :id => integer_parameters(:one).to_param, :integer_parameter => { }
    assert_redirected_to integer_parameter_path(assigns(:integer_parameter))
  end

  test "should destroy integer_parameter" do
    assert_difference('IntegerParameter.count', -1) do
      delete :destroy, :id => integer_parameters(:one).to_param
    end

    assert_redirected_to integer_parameters_path
  end
end
