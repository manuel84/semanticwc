class PlayersController < ApplicationController
  caches_action :index

  def index
    @player = get_player(params[:uri])
    @team_stations = get_player_team_stations(@player.uri)
  end

end
