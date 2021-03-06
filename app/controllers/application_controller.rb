class ApplicationController < ActionController::Base
  include RdfHelper
  caches_action :index, :cache_path => Proc.new { |c| c.params }
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
