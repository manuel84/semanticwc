class TrainersController < ApplicationController

  def index
    #http://localhost:3000/pages?uri=2014-06-13_Mexiko_Kamerun
    #&filter_type=group&filter_value=a
    o = OpenLigaDbDataWrapper.new
    @matchdays = o.brasil_matches o.brasil_rounds.first
    if params[:uri] && params[:uri].starts_with?('team_')
      render :team
    elsif params[:uri] && params[:uri].starts_with?('player_')
      render :player
    else
      @current_index = @matchdays.index { |m| m.last.first.first.eql?(params[:uri]) } || 0
      @matchday = @matchdays[@current_index]
      render text: 'not avaibable' unless @current_index
    end

  end

end
