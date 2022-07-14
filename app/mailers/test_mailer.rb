class TestMailer < ApplicationMailer
  helper :application

  def test_email
    @user = params[:user]
    @name = @user.name
    @email = @user.email
    @test_date = Time.now
    mail(to: @email, subject: "Test email from Drafter: #{@test_date}")
  end

end
