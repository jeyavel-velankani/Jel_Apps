class UserMailer < ApplicationMailer
  default from: 'notifications@jelapp.com'

  # require "letter_opener"
	
  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end

  def update_email(user)
  	@user = user
    @url  = 'http://jelapp.com/login'
    mail(to: @user.email, subject: 'Update to My Awesome Site')
  end

end
