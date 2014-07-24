class TrainersController < ApplicationController

  def index
    @trainer = get_trainer(params[:uri])
  end

end
