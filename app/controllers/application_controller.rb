class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  def home
  end

  def authenticate_admin!
    redirect_to new_user_session_path unless current_user && current_user.admin?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit({ notification_type_ids: [] }, :name, :email, :password, :password_confirmation) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit({ notification_type_ids: [] }, :name, :email, :password, :password_confirmation, :current_password) }
  end
end
