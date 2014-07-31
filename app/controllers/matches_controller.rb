class MatchesController < ApplicationController

  def index
    #http://localhost:3000/pages?uri=2014-06-13_Mexiko_Kamerun
    #&filter_type=group&filter_value=a
    @filter_value = params[:filter_uri] || ''

    @matchdays, @filter_type = get_matches(@filter_value)
    @current_index = @matchdays.index { |matchday| matchday.uri.to_s.eql?(params[:uri]) } || 0
    @matchday = @matchdays[@current_index]
    @home = get_team(@matchday.homeCompetitor_uri)
    @away = get_team(@matchday.awayCompetitor_uri)
    @stadium = get_stadium(@matchday.venue_uri)
    #o = OpenLigaDbDataWrapper.new
    #@matchdays = o.brasil_matches o.brasil_rounds.first

    #  @current_index = @matchdays.index { |m| m.last.first.first.eql?(params[:uri]) } || 0
    #  @matchday = @matchdays[@current_index]


  end

end
