class SfgCrawler < DataCrawler
  def self.crawl
    #pfad zur datei und vocab uri in klassenvariablen auslagern
    bbcsport = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/sport/")
    bbcevent = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/event/")
    soccer = RDF::Vocabulary.new("http://purl.org/hpi/soccer-voc/")
    swc14 = RDF::Vocabulary.new("http://cs.hs-rm.de/~mdudd001/semanticwc/")
    dbpedia = RDF::Vocabulary.new("http://dbpedia.org/resource/")
    event = RDF::Vocabulary.new("http://purl.org/NET/c4dm/event.owl#")
    part = RDF::Vocabulary.new("http://purl.org/vocab/participation/schema#")
    rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")

    graph = RDF::Graph.new

    #worldcup structure
    graph << [dbpedia["FIFA_World_Cup"], RDF.type, bbcsport.RecurringCompetition]
    graph << [dbpedia["FIFA_World_Cup"], bbcevent.recurringEvent, dbpedia["2014_FIFA_World_Cup"]]
    graph << [dbpedia["2014_FIFA_World_Cup"], RDF.type, bbcsport.MultiStageCompetition]
    graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.firstStage, swc14['Group_Stage']]
    graph << [swc14['Group_Stage'], RDF.type, bbcsport.KnockoutCompetition]


    result = RestClient.get "http://sfgapi.herokuapp.com/matches", {:accept => :json}
    matches = JSON.parse(result)

    #tema mapping wenn sonderzeichen im team namen vorhanden
    team_mappings = {"CIV" => "C%C3%B4te_d%27Ivoire_national_football_team",
                     "CRC" => "Costa_Rica_national_football_team",
                     "KOR" => "North_Korea_national_football_team",
                     "BIH" => "Bosnia_and_Herzegovina_national_football_team"}


    #stadium mapping,
    stadium_mappings = {"Arena da Baixada" => "Arena_da_Baixada",
                        "Estadio do Maracana" => "Est%C3%A1dio_do_Maracan%C3%A3",
                        "Arena de Sao Paulo" => "S%C3%A3o_Paulo",
                        "Arena Fonte Nova" => "Arena_Fonte_Nova",
                        "Arena Pantanal" => "Arena_Pantanal",
                        "Estadio das Dunas" => "Arena_das_Dunas",
                        "Estadio Beira-Rio" => "Est%C3%A1dio_Beira-Rio",
                        "Arena Amazonia" => "Arena_Amaz%C3%B4nia",
                        "Estadio Castelao" => "Castel%C3%A3o_(Cear%C3%A1)",
                        "Estadio Mineirao" => "Mineir%C3%A3o",
                        "Estadio Nacional" => "Est%C3%A1dio_Nacional_Man%C3%A9_Garrincha",
                        "Arena Pernambuco" => "Recife",}

    matches.each do |match|
        #gruppenphase nachbauen
        if match['stage'].include? "Group"
          graph << [swc14['Group_Stage'], bbcsport.hasGroup, swc14[match['stage'].gsub(/ /,"_")]]
        else
          if match['stage'].gsub(/ /,"_") == "Final"
            graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.lastStage, swc14[match['stage'].gsub(/ /,"_")]]
          else
            graph << [dbpedia["2014_FIFA_World_Cup"], bbcsport.hasStage, swc14[match['stage'].gsub(/ /,"_")]]
          end
          graph << [swc14[match['stage'].gsub(/ /,"_")], RDF.type, bbcsport.KnockoutCompetition]
        end

        #zu jeder gruppe die dazugehörigen teams hinzufügen TODO: hasCompetitor überprüfen
        if team_mappings[match['home_team']['code']]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[team_mappings[match['home_team']['code']]]]
          graph << [dbpedia[team_mappings[match['home_team']['code']]], rdfs.label, match['home_team']['country']]
        else
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[match['home_team']['country']+"_national_football_team"]]
          graph << [dbpedia[match['home_team']['country']+"_national_football_team"], rdfs.label, match['home_team']['country']]
        end
        if team_mappings[match['away_team']['code']]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[team_mappings[match['away_team']['code']]]]
          graph << [dbpedia[team_mappings[match['away_team']['code']]], rdfs.label, match['away_team']['country']]
        else
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[match['away_team']['country']+"_national_football_team"]]
          graph << [dbpedia[match['away_team']['country']+"_national_football_team"], rdfs.label, match['away_team']['country']]
        end


        #has match für jede gruppe und spiel hinzufügen
        graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasMatch, swc14[match['home_team']['code']+"_"+match['away_team']['code']]]

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
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], bbcsport.Venue, dbpedia[stadium_mappings[match['location']]]]

        #goals für jedes tem hinzufügen TODO: im moment ausgedachte ontology
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.homeCompetitorGoals, match['home_team']['goals']]
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.awayCompetitorGoals, match['away_team']['goals']]

        if match['winner']
          if team_mappings[match['winner']]
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.winner, dbpedia[team_mappings[match['winner']]]]
          else
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.winner, dbpedia[match['winner']+"_national_football_team"]]
          end
        end

        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']]]
        graph << [swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, match['datetime']]


      #end
    end

    RDF::Turtle::Writer.open(Rails.root.join('db', 'worldcup.ttl')) { |writer| writer << graph }

  end

end