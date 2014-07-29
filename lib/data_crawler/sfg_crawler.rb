require 'uri'

class SfgCrawler < DataCrawler
  def self.crawl
    #pfad zur datei und vocab uri in klassenvariablen auslagern
    bbcsport = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/sport/")
    bbcevent = RDF::Vocabulary.new("http://www.bbc.co.uk/ontologies/event/")
    soccer = RDF::Vocabulary.new("http://purl.org/hpi/soccer-voc/")
    swc14 = RDF::Vocabulary.new("http://cs.hs-rm.de/~mdudd001/semanticwc/")
    dbpedia = RDF::Vocabulary.new("http://dbpedia.org/resource/")
    ev = RDF::Vocabulary.new("http://purl.org/NET/c4dm/event.owl#")
    time = RDF::Vocabulary.new("http://www.w3.org/2006/time#")
    timeline = RDF::Vocabulary.new("http://purl.org/NET/c4dm/timeline.owl#")
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
          homeTeam = dbpedia[team_mappings[match['home_team']['code']]]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[team_mappings[match['home_team']['code']]]]
          graph << [homeTeam, rdfs.label, match['home_team']['country']]
          graph << [homeTeam, RDF.type, soccer.SoccerClub]
        else
          homeTeam = dbpedia[match['home_team']['country']+"_national_football_team"]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[match['home_team']['country']+"_national_football_team"]]
          graph << [homeTeam, rdfs.label, match['home_team']['country']]
          graph << [homeTeam, RDF.type, soccer.SoccerClub]
        end
        if team_mappings[match['away_team']['code']]
          awayTeam = dbpedia[team_mappings[match['away_team']['code']]]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[team_mappings[match['away_team']['code']]]]
          graph << [awayTeam, rdfs.label, match['away_team']['country']]
          graph << [awayTeam, RDF.type, soccer.SoccerClub]
        else
          awayTeam = dbpedia[match['away_team']['country']+"_national_football_team"]
          graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasCompetitor, dbpedia[match['away_team']['country']+"_national_football_team"]]
          graph << [awayTeam, rdfs.label, match['away_team']['country']]
          graph << [awayTeam, RDF.type, soccer.SoccerClub]
        end

        #match = match['home_team']['code']+"_"+match['away_team']['code']
        #has match für jede gruppe und spiel hinzufügen
        graph << [swc14[match['stage'].gsub(/ /,"_")], bbcsport.hasMatch, swc14[match['home_team']['code']+"_"+match['away_team']['code']]]
        graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], RDF.type, bbcsport.Match]

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
        #graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.homeCompetitorGoals, match['home_team']['goals']]
        #graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.awayCompetitorGoals, match['away_team']['goals']]

        #TODO: Winner gibt es nciht
        if match['winner'] != "Draw"
          if team_mappings[match['winner']]
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.winner, dbpedia[team_mappings[match['winner']]]]
          else
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], swc14.winner, dbpedia[match['winner']+"_national_football_team"]]
          end
        end

        #graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']]]
        #graph << [swc14["Event_"+match['home_team']['code']+"_"+match['away_team']['code']], part.startDate, match['datetime']]

        match['home_team_events'].each do |event|
            if event['type_of_event'] == "referee"
              graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.Referee, swc14[URI.encode(event['player'])]]
              graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.Referee]
            elsif event['type_of_event'] == "coach"
              #TODO: Manager gibt es nicht
              graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.Manager, swc14[URI.encode(event['player'])]]
              graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.SoccerManager]
            elsif event['type_of_event'] == "player"
              graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.startPlayer, swc14[URI.encode(event['player'])]]
              graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.SoccerPlayer]
              graph << [swc14[URI.encode(event['player'])], soccer.playsFor, homeTeam]
              graph << [swc14[URI.encode(event['player'])], rdfs.label, event['player']]
            elsif event['type_of_event'] == "goal-own" || event['type_of_event'] == "goal"
              goalEvent = match['home_team']['code']+"_"+match['away_team']['code']+"_Goal_"+SecureRandom.random_number(36**12).to_s(36).rjust(12, "0")
              timeEvent = match['home_team']['code']+"_"+match['away_team']['code']+"_Time_"+SecureRandom.random_number(36**12).to_s(36).rjust(12, "0")
              #calc date
              dateTime = RDF::Literal.new(event['time'], :datatype => RDF::XSD.int)
              graph << [swc14[goalEvent], soccer.match, swc14[match['home_team']['code']+"_"+match['away_team']['code']]]
              graph << [swc14[goalEvent], RDF.type, soccer.Goal]
              graph << [swc14[goalEvent], ev.agent, swc14[URI.encode(event['player'])]]
              graph << [swc14[goalEvent], ev.time, swc14[timeEvent]]
              graph << [swc14[timeEvent], RDF.type, timeline.Instant]
              graph << [swc14[timeEvent], timeline.atInt, dateTime]
            end
        end

        match['away_team_events'].each do |event|
          if event['type_of_event'] == "referee"
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.Referee, swc14[URI.encode(event['player'])]]
            graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.Referee]
          elsif event['type_of_event'] == "coach"
            #TODO: Manager gibt es nicht
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.Manager, swc14[URI.encode(event['player'])]]
            graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.SoccerManager]
          elsif event['type_of_event'] == "player"
            graph << [swc14[match['home_team']['code']+"_"+match['away_team']['code']], soccer.startPlayer, swc14[URI.encode(event['player'])]]
            graph << [swc14[URI.encode(event['player'])], RDF.type, soccer.SoccerPlayer]
            graph << [swc14[URI.encode(event['player'])], soccer.playsFor, homeTeam]
            graph << [swc14[URI.encode(event['player'])], rdfs.label, event['player']]
          elsif event['type_of_event'] == "goal-own" || event['type_of_event'] == "goal"
            goalEvent = match['home_team']['code']+"_"+match['away_team']['code']+"_Goal_"+SecureRandom.random_number(36**12).to_s(36).rjust(12, "0")
            timeEvent = match['home_team']['code']+"_"+match['away_team']['code']+"_Time_"+SecureRandom.random_number(36**12).to_s(36).rjust(12, "0")
            #calc date
            dateTime = RDF::Literal.new(event['time'], :datatype => RDF::XSD.int)
            graph << [swc14[goalEvent], soccer.match, swc14[match['home_team']['code']+"_"+match['away_team']['code']]]
            graph << [swc14[goalEvent], RDF.type, soccer.Goal]
            graph << [swc14[goalEvent], ev.agent, swc14[URI.encode(event['player'])]]
            graph << [swc14[goalEvent], ev.time, swc14[timeEvent]]
            graph << [swc14[timeEvent], RDF.type, timeline.Instant]
            graph << [swc14[timeEvent], timeline.atInt, dateTime]
          end
        end
      #end
    end

    RDF::Turtle::Writer.open(Rails.root.join('db', 'worldcup.ttl')) { |writer| writer << graph }

  end

end