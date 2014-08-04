class StadiumsController < ApplicationController
  caches_action :index

  def index
    @stadium = get_stadium(params[:uri])
    @matches, filter_type = get_matches(params[:uri])
  end

end
