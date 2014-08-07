class TrainersController < ApplicationController

  def index
    @trainer = get_trainer(params[:uri])
    @team_stations = get_trainer_team_stations(@trainer.uri)
  end

end
