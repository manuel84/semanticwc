class StadiumsController < ApplicationController

  def index
    @stadium = get_stadium(params[:uri])
    @matches = get_matches(params[:uri], 'stadium')
  end

end
