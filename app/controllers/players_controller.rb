class PlayersController < ApplicationController

  def index
    @player = get_player(params[:uri])
  end

end
