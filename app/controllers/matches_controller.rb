class MatchesController < ApplicationController

  def index
    @filter_value = params[:filter_uri] || ''

    @matches, @filter_type = get_matches(@filter_value)
    @current_index = @matches.index { |matchday| matchday.uri.to_s.eql?(params[:uri]) } || @matches.count-1
    @match = @matches[@current_index]
    @goals = get_goals(@match.uri)
    @home = get_team(@match.homeCompetitor_uri)
    @away = get_team(@match.awayCompetitor_uri)
    @stadium = get_stadium(@match.venue_uri)
  end

end
