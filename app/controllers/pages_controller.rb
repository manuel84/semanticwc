class PagesController < ApplicationController

  def index
    o = OpenLigaDbDataWrapper.new
    @matchdays = o.brasil_matches o.brasil_rounds.first
    @current_index = @matchdays.index { |m| m.last.first.first.eql?(params[:uri]) } || 0
    @matchday = @matchdays[@current_index]
    render text: 'not avaibable' unless @current_index
  end

end
