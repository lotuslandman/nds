class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_environment
#  before_application :application_update_database

  def set_environment
    session[:env] ||= "fntb_test"
    session[:end_date] ||= 1
    session[:start_date] ||= 5
#    session[:end_date] ||= Time.now #Time.parse(Time.now.to_s)
#    session[:start_date] ||= session[:end_date]-(20*60) # 6*60*60  this will be 6 hours and will eventually want this here
  end

#  def application_update_database
#    DeltaStream.update_database
#  end
  
end
