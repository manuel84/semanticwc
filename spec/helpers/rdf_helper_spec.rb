require 'spec_helper'
describe RdfHelper do
  describe '#ttl file' do
    it 'Fußball-Weltmeisterschaft_2014 has as MultiStageCompetition' do
      divisional_competitions = helper.get_multi_stage_competitions
      divisional_competitions.filter { |solution| solution.s.eql?(RDF::URI.new 'http://de.dbpedia.org/page/Fußball-Weltmeisterschaft_2014') }
      divisional_competitions.should_not be_empty
      #helper.write_to_xml
    end
  end

  it 'Koratien - Brasilien belongs to group A' do
    bra_cro = helper.get_match "#{PREFIX::WIKI}Fußball-Weltmeisterschaft_2014/Gruppe_A#Brasilien_.E2.80.93_Kroatien"
    bra_cro.round.to_s.should be_eql('Gruppe A')
  end

  it 'guess the uri of the brazilian national team by the name Brasilien' do
    teams = {'Brasilien' => ''}
    team_uris = teams.keys.map do |team_name|
      helper.get_team_uri team_name
    end
    expect(team_uris).to eql(teams.values)

  end

  it 'guess the uri of all brazilian players by their names and the team uri' do
    team_uri = 'http://dbpedia.org/resource/Brazil_national_football_team'
    players = {'Jefferson' => 'http://dbpedia.org/resource/Jefferson_de_Oliveira_Galv%C3%A3o', 'César, Júlio' => 'http://dbpedia.org/resource/J%C3%BAlio_C%C3%A9sar_Soares_Esp%C3%ADndola', 'Victor' => 'http://dbpedia.org/resource/Victor_Leandro_Bagy', 'Alves, Dani' => 'http://dbpedia.org/resource/Daniel_Alves', 'Silva, Thiago' => 'http://dbpedia.org/resource/Thiago_Silva_(footballer)', 'Luiz, David' => 'http://dbpedia.org/resource/David_Luiz', 'Marcelo' => 'http://dbpedia.org/resource/Marcelo_Ant%C3%B4nio_Guedes_Filho', 'Dante' => 'http://dbpedia.org/resource/Dante_Bonfim_Costa_Santos', 'Maxwell' => 'http://dbpedia.org/resource/Maxwell_Cabelino_Andrade', 'Henrique' => 'http://dbpedia.org/resource/Henrique_Adriano_Buss', 'Maicon' => 'http://dbpedia.org/resource/Maicon_Sisenando', 'Fernandinho' => 'http://dbpedia.org/resource/Fernando_Luiz_Roza', 'Paulinho' => 'http://dbpedia.org/resource/Jos%C3%A9_Paulo_Bezerra_Maciel_J%C3%BAnior', 'Oscar' => 'http://dbpedia.org/resource/Oscar_(footballer_born_1991)', 'Ramires' => 'http://dbpedia.org/resource/Ramires', 'Gustavo, Luiz' => 'http://dbpedia.org/resource/Luiz_Gustavo', 'Hernanes' => 'http://dbpedia.org/resource/Hernanes', 'Willian' => 'http://dbpedia.org/resource/Willian_Borges_da_Silva', 'Hulk' => 'http://dbpedia.org/resource/Hulk_(footballer)', 'Fred' => 'http://dbpedia.org/resource/Frederico_Chaves_Guedes', 'Neymar' => 'http://dbpedia.org/resource/Neymar', 'Bernard' => 'http://dbpedia.org/resource/Bernard_An%C3%ADcio_Caldeira_Duarte', 'Jô' => 'http://dbpedia.org/resource/J%C3%B4'}
    player_uris = players.keys.map do |player_name|
      helper.get_player_uri player_name, team_uri
    end
    expect(player_uris).to eql(players.values)
  end

end