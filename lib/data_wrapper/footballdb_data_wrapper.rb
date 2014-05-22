class FootballdbDataWrapper < DataWrapper
  # football.db doesnt support kickoff times
  # teilweise falsche Datumswerte

  API_HOST = 'http://footballdb.herokuapp.com/'
  BASE_PATH = 'api/v1/event/world.2014'

  def initialize

  end

end