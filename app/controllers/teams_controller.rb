class TeamsController < ApplicationController

  def index
    @team = get_team(params[:uri])
    @title = @team.label
    @players = get_players(params[:uri])
  end

end
