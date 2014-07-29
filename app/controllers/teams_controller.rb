class TeamsController < ApplicationController

  def index
    @team = get_team(params[:uri])
    @title = @team.label
    @players = get_players_for_team(params[:uri])
    #@trainer = get_trainer(@team.coach_uri)
  end

end
