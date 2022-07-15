class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:edit, :show, :update, :destroy, :switch_setting]
  after_action :verify_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :index_redirect

  def index
    authorize User
    @collection = record_scope.includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
  end

  def new
    @user = User.new
    organization_id = params[:organization_id]
    if policy(@user).assign_to_organization? && organization_id
      @user.organization_id = organization_id
    end
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user
    respond_to do |format|
      if @user.save
        format.html { redirect_to users_path, notice: 'Created new user'}
      else
        format.html { render :new }
      end
    end
  end

  def show
    authorize @user
    redirect_to edit_user_path(@user)
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to edit_user_path(@user), notice: 'Account Information updated'} 
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    authorize @user
    @user.destroy
    redirect_to users_path, notice: 'User was deleted'
  end

  private

  def record_scope
    policy_scope(User)
  end

  def set_user
    @user = record_scope.find(params[:id])
  end

  def user_params
    if params[:user].present?
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
    end
    allowed_params = policy(@user||User).allowed_params
    params.require(:user).permit(*allowed_params)
  end

  def index_redirect
    redirect_to users_path
  end

end
