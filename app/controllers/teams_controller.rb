class TeamsController < ApplicationController

  def index
    @team = get_team(params[:uri]) #includes trainer info
    @title = @team.label
    @players = get_players_for_team(params[:uri])
    @matches, filter_type = get_matches(params[:uri])
    #@trainer = get_trainer(@team.coach_uri)
  end

end
