class PagesController < ApplicationController

  def index
    prefix = 'http://localhost:3000/matchdays/'
    @matchdays = (1..64).map { |i| "#{prefix}#{i}" }
    @matchday = params[:uri]
    @current_index = @matchdays.index(@matchday)
    render text: 'not avaibable' unless @current_index
  end

end
