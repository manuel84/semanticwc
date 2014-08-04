class StadiumsController < ApplicationController

  def index
    @stadium = get_stadium(params[:uri])
    @matches, filter_type = get_matches(params[:uri])
  end

end
