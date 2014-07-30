class PlayersController < ApplicationController

  def index
    p = tmp_get_player(params[:uri])
    if p
      p_uri = get_player_uri(p.label.to_s, p.team_uri)
      puts p.label.to_s
      puts p_uri
      redirect_to players_path(uri: p_uri)
    else
      @player = get_player(params[:uri])
    end
  end

end
