class OpenLigaDbDataWrapper < DataCrawler
  WSDL = 'http://www.OpenLigaDB.de/Webservices/Sportsdata.asmx?WSDL'

  attr_accessor :client

  def initialize
    @client = Savon.client(wsdl: WSDL, log: true)
  end

  def get_all_leagues
    res.body[:get_avail_leagues_response][:get_avail_leagues_result][:league]
  end

  def brasil_rounds
    res = client.call :get_avail_groups, message: {leagueShortcut: "wm_brasilien", leagueSaison: "2014"}
    rounds = res.body[:get_avail_groups_response][:get_avail_groups_result][:group]
    rounds.map do |round|
      object_resource = [
          [round[:group_name], "name", round[:group_name]],
          [round[:group_name], "open_liga_db_group_order_id", round[:group_order_id]],
          [round[:group_name], "open_liga_db_group_id", round[:group_id]]
      ]
      ["WM2014", "round", object_resource]
    end
  end

  def brasil_matches round_tripel
    round_name = round_tripel.last.select { |sub_tripel| sub_tripel[1].eql?("name") }.last
    group_order_id = round_tripel.last.select { |sub_tripel| sub_tripel[1].eql?("open_liga_db_group_order_id") }.last
    res = client.call :get_matchdata_by_league_saison, message: {groupOrderID: group_order_id, leagueShortcut: "wm_brasilien", leagueSaison: "2014"}
    matchdays = res.body[:get_matchdata_by_league_saison_response][:get_matchdata_by_league_saison_result][:matchdata]
    matchdays.map do |matchday|
      m_name = "#{matchday[:match_date_time].to_date.to_s(:db)}_#{matchday[:name_team1]}_#{matchday[:name_team2]}"
      object_resource = [
          [m_name, "time", matchday[:match_date_time]],
          [m_name, "team1", matchday[:name_team1]],
          [m_name, "team2", matchday[:name_team2]],
          [m_name, "team1_icon", matchday[:icon_url_team1]],
          [m_name, "team2_icon", matchday[:icon_url_team2]],
          [m_name, "city", matchday[:location][:location_city]],
          [m_name, "stadium", matchday[:location][:location_stadium]]
      ]
      [round_name, "match", object_resource]
    end
  end
end