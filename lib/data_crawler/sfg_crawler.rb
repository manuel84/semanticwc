class SfgCrawler < DataCrawler
  def self.crawl
    bbcsport = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/sport/")
    bbcevent = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/event/")
    soccer = RDF::Vocabulary.new("http://purl.org/hpi/soccer-voc/")
    swc14 = RDF::Vocabulary.new("http://cs.hs-rm.de/~mdudd001/semanticwc")
    dbpedia = RDF::Vocabulary.new("http://dbpedia.org/resource/")
    event = RDF::Vocabulary.new("http://purl.org/NET/c4dm/event.owl#")
    part = RDF::Vocabulary.new("http://purl.org/vocab/participation/schema")
    rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")

    graph = RDF::Graph.new

#worldcup structure
    graph << [dbpedia["FIFA_World_Cup"], RDF.type, bbcsport.RecurringCompetition]
    graph << [dbpedia["FIFA_World_Cup"], bbcevent.recurringEvent, dbpedia["2014_FIFA_World_Cup"]]
    graph << [dbpedia["2014_FIFA_World_Cup"], RDF.type, bbcsport.MultiStageCompetition]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.firstStage, swc14['Vorrunde']]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.lastStage, swc14['Finale']]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.hasStage, swc14['Achtelfinale']]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.hasStage, swc14['Viertelfinale']]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.hasStage, swc14['Halbfinale']]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.hasStage, swc14['Spiel_um_Platz_3']]
    graph << [swc14['Vorrunde'], RDF.type, bbcsport.KnockoutCompetition]
    graph << [swc14['Finale'], RDF.type, bbcsport.KnockoutCompetition]
    graph << [swc14['Achtelfinale'], RDF.type, bbcsport.KnockoutCompetition]
    graph << [swc14['Viertelfinale'], RDF.type, bbcsport.KnockoutCompetition]
    graph << [swc14['Halbfinale'], RDF.type, bbcsport.KnockoutCompetition]
    graph << [swc14['Spiel_um_Platz_3'], RDF.type, bbcsport.KnockoutCompetition]


    result = RestClient.get "http://worldcup.sfg.io/matches", {:accept => :json}
    matches = JSON.parse(result)

    result = RestClient.get "http://worldcup.sfg.io/teams/group_results", {:accept => :json}
    groups = JSON.parse(result)

#tema mapping wenn sonderzeichen im team namen vorhanden sind TODO: richtigen links eintragen
    team_mappings = {"CIV" => "http://dbpedia.org/resource/C%C3%B4te_d%27Ivoire_national_football_team",
                     "CRC" => "http://dbpedia.org/resource/Costa_Rica_national_football_team",
                     "KOR" => "http://dbpedia.org/resource/North_Korea_national_football_team",
                     "BIH" => "http://dbpedia.org/resource/Bosnia_and_Herzegovina_national_football_team"}

    groups.each do |group|
      #jede gruppe hinzufügen
      graph << [swc14['Vorrunde'], bbcsport.hasGroup, swc14[group['group']['letter']]]
      graph << [swc14['Vorrunde'], rdfs.label, "Gruppe_"+group['group']['letter']]
      group['group']['teams'].each do |team|

        #zu jeder gruppe die dazugehörigen teams hinzufügen TODO: hasMember ist ausgedacht
        if team_mappings[team['team']['fifa_code']]
          graph << [swc14[group['group']['letter']], bbcsport.hasMember, dbpedia[team_mappings[team['team']['fifa_code']]]]
        else
          graph << [swc14[group['group']['letter']], bbcsport.hasMember, dbpedia[team['team']['country']+"_national_football_team"]]
        end

      end
    end

#match id zu Gruppe, bei die spielen ist kein information vorhanden zu welcher gruppe sie gehören
    match_group_mapping = {1 => "A", 2 => "A", 3 => "A", 4 => "A", 5 => "A", 6 => "A", 7 => "A", 8 => "A", 9 => "A", 10 => "A",
                           11 => "A", 12 => "A", 13 => "A", 14 => "A", 15 => "A", 16 => "A", 17 => "A", 18 => "A", 19 => "A", 20 => "A",
                           21 => "A", 22 => "A", 23 => "A", 24 => "A", 25 => "A", 26 => "A", 27 => "A", 28 => "A", 29 => "A", 30 => "A",
                           31 => "A", 32 => "A", 33 => "A", 34 => "A", 35 => "A", 36 => "A", 37 => "A", 38 => "A", 39 => "A", 40 => "A",
                           41 => "A", 42 => "A", 43 => "A", 44 => "A", 45 => "A", 46 => "A", 47 => "A", 48 => "A", 49 => "A", 50 => "A",
                           51 => "A", 52 => "A"
    }
#stadium mapping, TODO: recife überprüfen
    stadium_mappings = {"BRA" => "http://dbpedia.org/resource/Bras%C3%ADlia",
                        "BRA" => "http://dbpedia.org/resource/Fortaleza",
                        "BRA" => "http://dbpedia.org/resource/Salvador,_Bahia",
                        "Arena da Baixada" => "http://dbpedia.org/resource/Arena_da_Baixada",
                        "Estadio do Maracana" => "http://dbpedia.org/resource/Est%C3%A1dio_do_Maracan%C3%A3",
                        "BRA" => "http://dbpedia.org/resource/Natal,_Rio_Grande_do_Norte",
                        "BRA" => "http://dbpedia.org/resource/Belo_Horizonte",
                        "BRA" => "http://dbpedia.org/resource/Curitiba",
                        "BRA" => "http://dbpedia.org/resource/Manaus",
                        "BRA" => "http://dbpedia.org/resource/Porto_Alegre",
                        "BRA" => "http://dbpedia.org/resource/Rio_de_Janeiro",
                        "Arena de Sao Paulo" => "http://dbpedia.org/resource/S%C3%A3o_Paulo",
                        "BRA" => "http://dbpedia.org/resource/Arena_Cidade_da_Copa",
                        "Arena Fonte Nova" => "http://dbpedia.org/resource/Arena_Fonte_Nova",
                        "Arena Pantanal" => "http://dbpedia.org/resource/Arena_Pantanal",
                        "Estadio das Dunas" => "http://dbpedia.org/resource/Arena_das_Dunas",
                        "Estadio Beira-Rio" => "http://dbpedia.org/resource/Est%C3%A1dio_Beira-Rio",
                        "Arena Amazonia" => "http://dbpedia.org/resource/Arena_Amaz%C3%B4nia",
                        "Estadio Castelao" => "http://dbpedia.org/resource/Castel%C3%A3o_(Cear%C3%A1)",
                        "Estadio Mineirao" => "http://dbpedia.org/resource/Mineir%C3%A3o",
                        "Estadio Nacional" => "http://dbpedia.org/resource/Est%C3%A1dio_Nacional_Man%C3%A9_Garrincha",
                        "BRA" => "http://dbpedia.org/resource/Arena_de_S%C3%A3o_Paulo",
                        "Arena Pernambuco" => "http://dbpedia.org/resource/Recife",
                        "URU" => "http://dbpedia.org/resource/Cuiab%C3%A1"}

    matches.each do |match|

      if match['match_number'] <= 52 #nur gruppenphase
        #has match für jede gruppe und spiel hinzufügen
        graph << [swc14[match_group_mapping[match['match_number']]], bbcsport.hasMatch, swc14[match['home_team']['code']+"_"+match['away_team']['code']]]

        #für jedes spiel hometeam hinzufügen
        if team_mappings[match['home_team']['code']]
          graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], bbcsport.homeCompetitor, dbpedia[team_mappings[match['home_team']['code']]]]
        else
          graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], bbcsport.homeCompetitor, dbpedia[match['home_team']['country']+"_national_football_team"]]
        end

        #für jedes spiel awayteam hinzufügen
        if team_mappings[match['away_team']['code']]
          graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], bbcsport.awayCompetitor, dbpedia[team_mappings[match['away_team']['code']]]]
        else
          graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], bbcsport.awayCompetitor, dbpedia[match['away_team']['country']+"_national_football_team"]]
        end

        #für jedes spiel stadion hinzufügen
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.Stadium, dbpedia[stadium_mappings[match['location']]]]

        #goals für jedes tem hinzufügen TODO: im moment ausgedachte ontology
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.homeCompetitorGoals, match['home_team']['goals']]
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.awayCompetitorGoals, match['away_team']['goals']]

        if match['winner']
          graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.winner, match['winner']]
        end

        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']]]
        graph << [swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, match['datetime']]


      end
    end

    RDF::Writer.open("worldcup.nt") { |writer| writer << graph }

  end

end