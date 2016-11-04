class ApplicationController < ActionController::Base
  include Pundit

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # https://github.com/plataformatec/devise/pull/4033/files
  protect_from_forgery with: :exception, prepend: true

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    if resource.has_role?(:voter, :any)
      existing = resource.open_ride
      return edit_ride_path(existing) if existing

      # TODO: handle es path
      return "/ride/#{resource.voter_ride_zone_id}"
    end

    if resource.is_super_admin?
      admin_path
    elsif resource.is_dispatcher?
      dispatch_path( RideZone.with_user_in_role(current_user, :dispatcher).first.slug)
    elsif resource.is_zone_admin?
      # with that with_user_in_role work on a specific RZ? Verify
      dispatch_path( RideZone.with_user_in_role(current_user, :admin).first.slug)
    elsif resource.is_driver?
      driving_index_path
    else
      root_path
    end
  end

  protected

  def set_locale
    if request.path.include?('conseguir_un_paseo')
      I18n.locale = 'es'
    elsif params[:locale].present? && (params[:locale] == 'en' || params[:locale] == 'es')
      I18n.locale = params[:locale]
    else
      I18n.locale = I18n.default_locale
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:user_type, :name, :description, :email, :phone_number, :zip, :city, :state, :city_state, :ride_zone_id])
  end

end
