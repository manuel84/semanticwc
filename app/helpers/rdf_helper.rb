# @author Manuel Dudda <dudda@redpeppix.de>
module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'db', 'worldcup.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)
  DBPEDIA = SPARQL::Client.new('http://dbpedia.org/sparql')

  def get_multi_stage_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{RDF.type}> <#{PREFIX::BBCSPORT}MultiStageCompetition> }")
    solutions = QUERYABLE.query(sparql)
  end

  # returns all matches filtered by a specific filter.
  # The matches will be ordered by time ascending .
  # Each match contains
  # uri,
  # homeCompetitor,
  # homeCompetitor_uri,
  # awayCompetitor,
  # awayCompetitor_uri,
  # round,
  # round_uri
  # venue_uri
  # time
  #
  # @param filter_uri [String] the filter type, can be a group, day, stadium, team or none filter
  # @return [RDF::Query::Solutions] the array-similar object of RDF::Query::Solution
  def get_matches(filter_uri=nil)
    filter_type = ''
    optional_filter = if filter_uri
                        if filter_uri =~ /\d{4}\-\d{2}\-\d{2}/
                          filter_type = 'day'
                          "FILTER(?time >= \"#{filter_uri}T00:00:00.000-03:00\"^^<http://www.w3.org/2001/XMLSchema#dateTime> && ?time <= \"#{filter_uri}T23:59:59.000-03:00\"^^<http://www.w3.org/2001/XMLSchema#dateTime>)"
                        else
                          sparql = SPARQL.parse("SELECT ?stadium ?type ?group WHERE {
                                  ?s ?p ?o .
                                  OPTIONAL { ?stadium <http://www.bbc.co.uk/ontologies/sport/Venue> <#{filter_uri}> . }.
                                  OPTIONAL { <#{filter_uri}> <#{RDF.type}> ?type . }.
                                  OPTIONAL { <#{filter_uri}> <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?group . }.
                        }")
                          solution = QUERYABLE.query(sparql).first
                          if solution.has_variables? ['stadium']
                            filter_type = 'stadium'
                            "?uri <#{PREFIX::BBCSPORT}Venue> <#{filter_uri}> ."
                          elsif solution.has_variables? ['group']
                            filter_type = 'group'
                            "<#{filter_uri}> <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?uri ."
                          elsif solution.has_variables? ['type']
                            if solution.type.to_s.eql?('http://purl.org/hpi/soccer-voc/SoccerClub')
                              filter_type = 'team'
                              "{ ?uri <#{PREFIX::BBCSPORT}homeCompetitor> <#{filter_uri}> . } UNION { ?uri <#{PREFIX::BBCSPORT}awayCompetitor> <#{filter_uri}> . }"
                            end
                          else
                            ''
                          end
                        end
                      end
    sparql = SPARQL.parse("
              SELECT ?uri ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri ?venue_uri ?time ?homeCompetitorGoals ?awayCompetitorGoals
              WHERE {
                ?uri <#{RDF.type}> <#{PREFIX::BBCSPORT}Match> .
                ?uri <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
                ?homeCompetitor_uri <#{RDF::RDFS.label}> ?homeCompetitor .
                ?uri <#{PREFIX::BBCSPORT}awayCompetitor> ?awayCompetitor_uri .
                ?awayCompetitor_uri <#{RDF::RDFS.label}> ?awayCompetitor .
                ?uri <#{PREFIX::BBCSPORT}Venue> ?venue_uri .
                ?uri <http://purl.org/NET/c4dm/event.owl#time> ?time .
                OPTIONAL { ?uri <http://www.bbc.co.uk/ontologies/sport/homeCompetitorGoals> ?homeCompetitorGoals . }.
                OPTIONAL { ?uri <http://www.bbc.co.uk/ontologies/sport/awayCompetitorGoals> ?awayCompetitorGoals . }.
                #{optional_filter}
              }
              ORDER BY ASC(?time)
              ")
    solutions = QUERYABLE.query(sparql)
    return solutions, filter_type
  end

  def get_teams
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?name
                    WHERE {
                      ?group_uri <http://www.bbc.co.uk/ontologies/sport/hasCompetitor> ?uri .
                      ?uri <#{RDF::RDFS.label}> ?name .
                    }")
    solutions = QUERYABLE.query(sparql)
  end

  def get_stadiums
    sparql = SPARQL.parse('SELECT DISTINCT ?uri
                WHERE {
                  ?match <http://www.bbc.co.uk/ontologies/sport/Venue> ?uri .
                }')
    results = QUERYABLE.query(sparql).map { |sol| get_stadium(sol.uri) }
  end

  def get_groups
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label
                    WHERE {
                      ?uri <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?match_uri .
                      ?uri <#{RDF::RDFS.label}> ?label .
                    }")
    results = QUERYABLE.query(sparql)
  end

  def get_days
    sparql = SPARQL.parse("SELECT DISTINCT ?time
                    WHERE {
                      ?match <#{RDF.type}> <http://www.bbc.co.uk/ontologies/sport/Match> .
                      ?match <http://purl.org/NET/c4dm/event.owl#time> ?time .
                    }")
    results = QUERYABLE.query(sparql).map { |sol| Date.parse(sol.time.to_s) }.uniq
  end

  # return a match given by a specific uri.
  # A match contains
  # uri,
  # homeCompetitor,
  # homeCompetitor_uri,
  # awayCompetitor,
  # awayCompetitor_uri,
  # round,
  # round_uri
  #
  # @example
  #   match = get_match "http://de.wikipedia.org/wiki/Fußball-Weltmeisterschaft_2014/Gruppe_A#Brasilien_.E2.80.93_Kroatien"
  #   #=> #<RDF::Query::Solution:0x8363f514(
  #     {:homeCompetitor_uri=>#<RDF::URI:0x82defd64 URI:http://de.wikipedia.org/wiki/Brasilianische_Fußballnationalmannschaft>,
  #      :homeCompetitor=>#<RDF::Literal:0x834d7c80("Brasilien")>,
  #      :awayCompetitor_uri=>#<RDF::URI:0x82dde2d0 URI:http://de.wikipedia.org/wiki/Kroatische_Fußballnationalmannschaft>,
  #      :awayCompetitor=>#<RDF::Literal:0x834bbcd8("Kroatien")>,
  #      :round_uri=>#<RDF::URI:0x82e4ebe8 URI:http://de.wikipedia.org/wiki/Fußball-Weltmeisterschaft_2014#Gruppe_A>,
  #      :round=>#<RDF::Literal:0x82e2aacc("Gruppe A")>})>
  #   match.homeCompetitor #=> #<RDF::Literal:0x834d7c80("Brasilien")>
  #   match.homeCompetitor.to_s #=> "Brasilien"
  # @param uri [String] the uri of the match
  # @return [RDF::Query::Solution] the match
  def get_match(uri)
    sparql = SPARQL.parse("SELECT ?uri ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri
    WHERE {
            ?uri <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
            <#{uri}> <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
            ?homeCompetitor_uri <#{RDF::RDFS.label}> ?homeCompetitor .
            <#{uri}> <#{PREFIX::BBCSPORT}awayCompetitor> ?awayCompetitor_uri .
            ?awayCompetitor_uri <#{RDF::RDFS.label}> ?awayCompetitor .
            ?round_uri <#{PREFIX::BBCSPORT}hasMatch> <#{uri}> .
            ?round_uri <#{RDF::RDFS.label}> ?round .
            }")
    solution = QUERYABLE.query(sparql).first
  end

  def get_group(uri)
    sparql = SPARQL.parse("SELECT ?uri ?label
      WHERE {
              ?uri <#{RDF::RDFS.label}> ?label .
              <#{uri}> <#{RDF::RDFS.label}> ?label .
              }")
    solution = QUERYABLE.query(sparql).first
  end


  def get_goals(uri)
    sparql = SPARQL.parse("SELECT DISTINCT ?goal_uri ?player_uri ?player ?factor ?time_uri ?time
          WHERE {
            ?goal_uri <http://purl.org/hpi/soccer-voc/match> <#{uri}> .
            ?goal_uri <#{RDF.type}> <http://purl.org/hpi/soccer-voc/Goal> .
            ?goal_uri <http://purl.org/NET/c4dm/event.owl#agent> ?player_uri .
            ?player_uri <#{RDF::RDFS.label}> ?player .
            ?goal_uri <http://purl.org/NET/c4dm/event.owl#literal_factor> ?factor .
            ?goal_uri <http://purl.org/NET/c4dm/event.owl#time> ?time_uri .
            ?time_uri <http://purl.org/NET/c4dm/timeline.owl#atInt> ?time .
      }
      ORDER BY ASC(?time)
")
    solutions = QUERYABLE.query(sparql)
  end

  # guess a team uri by a given team name
  def get_team_uri(name)
    #sparql = "SELECT ?uri WHERE { ?uri <http://dbpedia.org/property/fifaTrigramme> \"#{name}\" . }"
    #solution = DBPEDIA.query(sparql).first
    exceptions = {'USA' => 'Vereinigte Staaten'}
    name = exceptions[name] if exceptions.has_key?(name)
    sparql = "
    SELECT DISTINCT ?country_name
            WHERE {
              ?country_uri <#{RDF::RDFS.label}> \"#{name}\"@de .
              ?country_uri  <#{RDF::RDFS.label}> ?country_name .
              ?country_uri <http://dbpedia.org/property/commonName> ?common_name .
              FILTER ( LANG(?country_name) = 'en' )
            }
    "
    solutions = DBPEDIA.query sparql
    country_name = solutions.first ? solutions.first.country_name.to_s.gsub(' ', '_') + '_national_football_team' : ''
    "http://dbpedia.org/resource/#{country_name}"
  end

  # return a team given by a specific uri.
  # A team contains
  # uri,
  #
  # @param uri [String] the uri of the team
  # @return [RDF::Query::Solution] the team
  def get_team(uri, lang_filter=true)
    filter = "FILTER (str(?uri) = '#{uri}'"
    filter += lang_filter ? "&& LANG(?label) = 'de')" : ')'
    sparql = "SELECT ?uri ?label ?name ?image_url ?thumbnail_url ?abstract ?coach ?coach_uri ?wiki_uri
        WHERE {
                ?uri <#{RDF::RDFS.label}> ?label .
                <#{uri}> <#{RDF::RDFS.label}> ?label .
                OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url } .
                OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url } .
                OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract } .
                OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/name> ?name FILTER ( LANG(?name) = 'de' ) } .
                OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/isPrimaryTopicOf> ?wiki_uri }.
                OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/coach> ?coach_uri .
                  ?coach_uri <http://xmlns.com/foaf/0.1/name> ?coach }.
                #{filter}
                }"
    solution = DBPEDIA.query(sparql).first
    solution ||= get_team(uri, false) if lang_filter
    return solution
  end

  # return a collection of player from a national team given by the team uri
  # A player contains
  # uri,
  # name
  # @param uri [String] the uri of the team
  # @return [RDF::Query::Solutions] the players
  def get_players_for_team(uri)
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label ?team_uri ?team
          WHERE {
            ?uri <http://purl.org/hpi/soccer-voc/playsFor> <#{uri}> .
            ?uri <#{RDF::RDFS.label}> ?label .
            ?uri <http://purl.org/hpi/soccer-voc/playsFor> ?team_uri .
            ?team_uri <#{RDF::RDFS.label}> ?team .
          }")
    solutions = QUERYABLE.query(sparql)
  end


  def tmp_get_player(uri)
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label ?team_uri ?team
          WHERE {
            <#{uri}> <#{RDF::RDFS.label}> ?label .
            <#{uri}> <http://purl.org/hpi/soccer-voc/playsFor> ?team_uri .
            ?team_uri <#{RDF::RDFS.label}> ?team .
          }")
    solutions = QUERYABLE.query(sparql).first
  end

  # guess a player uri by a given name and team
  # @param name [String] the name of the player
  # @return [RDF::Query::Solution] the player
  def get_player_uri(name, team_uri)
    if name.include?(',')
      name = name.split(',').reverse.join(' ')
    end
    name = name.strip
    sparql = "SELECT DISTINCT ?player_uri ?team_uri
        WHERE {
          { ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/fullname> \"#{name}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/surname> \"#{name}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/fullname> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/surname> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name.split(' ').last}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/fullname> \"#{name.split(' ').last}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/surname> \"#{name.split(' ').last}\"@en . }
          ?player_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerPlayer> .
          ?player_uri <http://dbpedia.org/property/nationalteam> <#{team_uri}> .
          OPTIONAL { ?player_uri <http://dbpedia.org/property/nationalcaps> ?caps }.
          OPTIONAL { ?player_uri <http://dbpedia.org/property/nationalgoals> ?goals }.
          ?player_uri <http://dbpedia.org/property/birthDate> ?birth_date .
          FILTER(?birth_date > \"19700101\"^^xsd:date)
        }
        ORDER BY DESC(?caps) DESC(?goals)"
    solutions = DBPEDIA.query sparql
    result = solutions.first
    puts "#{name} : #{result.player_uri.to_s}" if result
    result.present? ? result.player_uri.to_s : nil
  end

  # return a player given by a specific uri.
  # A player contains
  # uri,
  # firstName         FOAF
  # firstName_uri     FOAF
  # familyName        FOAF
  # familyName_uri    FOAF
  # playsFor          Soccer Voc
  # playsFor_uri      Soccer Voc
  # TODO...
  # @param uri [String] the uri of the player
  # @return [RDF::Query::Solution] the player
  def get_player(uri)
    sparql = "SELECT DISTINCT ?uri ?name ?surname ?givenName ?fullname ?position ?birth_date ?current_club_uri ?current_club ?image_url ?thumbnail_url ?abstract ?team ?team_uri ?caps ?goals
          WHERE {
            ?uri <http://dbpedia.org/property/name> ?name .
            <#{uri}> <http://dbpedia.org/property/name> ?name .
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/surname> ?surname }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/givenName> ?givenName }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/fullname> ?fullname }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/nationalcaps> ?caps }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/nationalgoals> ?goals }.
            OPTIONAL {  <#{uri}> <http://dbpedia.org/property/nationalteam> ?team_uri .
                        ?team_uri <#{RDF::RDFS.label}> ?team .
                        ?team_uri <http://dbpedia.org/property/fifaRank> ?fifa_rank .
                        FILTER(LANG(?team) = 'de')
                      }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/position> ?position }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/birthDate> ?birth_date }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/property/currentclub> ?current_club_uri .
                      ?current_club_uri <#{RDF::RDFS.label}> ?current_club
                      FILTER ( LANG(?current_club) = 'de')
                      }.
            OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url }.
            OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract .
                       FILTER(LANG(?abstract) = 'de') .
                      }.
          }
          ORDER BY DESC(?caps) DESC(?goals)"
    solution = DBPEDIA.query(sparql).first
  end

  # return a stadium given by a specific uri.
  # A stadium contains
  # uri,
  # BBC:Venue or smm:Stadium as subClassOf geo:SpatialThing
  # TODO...
  # @param uri [String] the uri of the stadium
  # @return [RDF::Query::Solution] the stadium
  def get_stadium(uri)
    sparql = "
    SELECT DISTINCT ?uri ?name ?city_uri ?city ?population ?lat ?long ?capacity ?seatingCapacity ?image_url ?thumbnail_url ?abstract
            WHERE {
              ?uri  <#{RDF::RDFS.label}> ?name .
              <#{uri}> <#{RDF::RDFS.label}> ?name .
              <#{uri}> <http://dbpedia.org/ontology/location> ?city_uri .
              ?city_uri <#{RDF::RDFS.label}> ?city .
              ?city_uri <http://dbpedia.org/ontology/populationTotal> ?population .
              <#{uri}> <http://www.w3.org/2003/01/geo/wgs84_pos#lat> ?lat .
              <#{uri}> <http://www.w3.org/2003/01/geo/wgs84_pos#long> ?long .
              OPTIONAL { <#{uri}> <http://dbpedia.org/property/capacity> ?capacity }.
              OPTIONAL { <#{uri}> <http://dbpedia.org/property/seatingCapacity> ?seatingCapacity }.
              OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url }.
              OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url }.
              OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract }.
              FILTER (str(?uri) = '#{uri}' && lang(?city) = 'en' && lang(?name) = 'en' && ?population > 5000)
            }
    "
    solutions = DBPEDIA.query(sparql).find_all { |sol| !sol.city_uri.to_s.eql?('http://dbpedia.org/resource/Brazil') }.first
  end

  def get_trainer(uri)
    sparql = "SELECT DISTINCT ?uri ?name ?surname ?givenName ?fullname ?birth_date ?image_url ?thumbnail_url ?abstract ?team_uri
           WHERE {
             ?uri <http://dbpedia.org/property/name> ?name .
             <#{uri}> <http://dbpedia.org/property/name> ?name .
             OPTIONAL { <#{uri}> <http://dbpedia.org/property/surname> ?surname }.
             OPTIONAL { <#{uri}> <http://dbpedia.org/property/givenName> ?givenName }.
             OPTIONAL { <#{uri}> <http://dbpedia.org/property/fullname> ?fullname }.
             OPTIONAL { <#{uri}> <http://dbpedia.org/property/birthDate> ?birth_date . }.
             OPTIONAL { <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url . }.
             OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url . }.
             OPTIONAL { <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract . FILTER ( LANG(?abstract) = 'de' ) }.
             OPTIONAL { ?team_uri <http://dbpedia.org/ontology/coach> <#{uri}> . }.
           }"
    solution = DBPEDIA.query(sparql).first
  end

  # guess a trainer uri by a given name and team
  # @param name [String] the name of the trainer
  # @return [RDF::Query::Solution] the trainer
  def get_trainer_uri(name, team_uri)
    if name.include?(',')
      name = name.split(',').reverse.join(' ')
    end
    name = name.strip
    sparql = "SELECT DISTINCT ?trainer_uri ?team_uri
        WHERE {
          ?trainer_uri <http://xmlns.com/foaf/0.1/name> \"#{name}\"@en .
          ?trainer_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerManager> .
          ?trainer_uri <http://dbpedia.org/ontology/coach> <#{team_uri}> .
          ?trainer_uri <http://dbpedia.org/property/birthDate> ?birth_date .
          FILTER(?birth_date > \"19000101\"^^xsd:date)
        }"
    solutions = DBPEDIA.query sparql
    result = case solutions.count
               when 0 # fallback
                 sparql = "SELECT DISTINCT ?trainer_uri ?team_uri
                WHERE {
                  ?trainer_uri <http://xmlns.com/foaf/0.1/name> \"#{name}\"@en .
                  ?trainer_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerManager> .
                  ?trainer_uri <http://dbpedia.org/property/birthDate> ?birth_date .
                  FILTER(?birth_date > \"19000101\"^^xsd:date)
                }"
                 solutions = DBPEDIA.query sparql
                 solutions.first
               when 1
                 solutions.first
               else
                 solutions.first
             end
    result.trainer_uri.to_s if result
  end

  # return all team stations with time period a player participated in descendant order given by a specific uri.
  # A team station contains
  # uri,
  # TODO...
  # @param uri [String] the uri of the player
  # @return [RDF::Query::Solutions] the team stations
  def get_player_team_stations(uri)
    sparql = "SELECT DISTINCT ?uri ?career_station_uri ?years ?team_uri ?clubname ?name ?nickname ?label ?altname
        WHERE {
          {
            ?uri <http://dbpedia.org/ontology/careerStation> ?career_station_uri .
            <#{uri}> <http://dbpedia.org/ontology/careerStation> ?career_station_uri .
            ?career_station_uri <http://dbpedia.org/ontology/years> ?years .
            ?career_station_uri <http://dbpedia.org/ontology/team> ?team_uri .
            OPTIONAL { ?team_uri <http://dbpedia.org/property/clubname> ?clubname . FILTER(LANG(?clubname) = 'en')}.
            OPTIONAL { ?team_uri <http://dbpedia.org/property/nickname> ?nickname . FILTER(LANG(?nickname) = 'en')}.
            OPTIONAL { ?team_uri <http://xmlns.com/foaf/0.1/name> ?name . FILTER(LANG(?name) = 'en')}.
            OPTIONAL { ?team_uri <#{RDF::RDFS.label}> ?label . FILTER(LANG(?label) = 'en') }.
            OPTIONAL { ?team_uri <http://dbpedia.org/property/fullname> ?altname . FILTER(LANG(?altname) = 'en') }.
          }
          MINUS { ?team_uri <http://dbpedia.org/property/association> ?association . }.
        }
        ORDER BY DESC(?years)"
    solutions = DBPEDIA.query sparql
    # do uniq
    Hash[solutions.reverse.map { |sol| [sol.career_station_uri.to_s, sol] }].values.reverse
  end

  # return all team stations with time period a player participated in descendant order given by a specific uri.
  # A team station contains
  # uri,
  # TODO...
  # @param uri [String] the uri of the player
  # @return [RDF::Query::Solutions] the team stations
  def get_trainer_team_stations(uri)
    sparql = "SELECT DISTINCT ?uri ?career_station_uri ?years ?team_uri ?clubname ?name ?nickname ?label ?altname
            WHERE {
              {
                ?uri <http://dbpedia.org/ontology/careerStation> ?career_station_uri .
                <#{uri}> <http://dbpedia.org/ontology/careerStation> ?career_station_uri .
                ?career_station_uri <http://dbpedia.org/ontology/years> ?years .
                ?career_station_uri <http://dbpedia.org/ontology/team> ?team_uri .
                OPTIONAL { ?team_uri <http://dbpedia.org/property/clubname> ?clubname . FILTER(LANG(?clubname) = 'en')}.
                OPTIONAL { ?team_uri <http://dbpedia.org/property/nickname> ?nickname . FILTER(LANG(?nickname) = 'en')}.
                OPTIONAL { ?team_uri <http://xmlns.com/foaf/0.1/name> ?name . FILTER(LANG(?name) = 'en')}.
                OPTIONAL { ?team_uri <#{RDF::RDFS.label}> ?label . FILTER(LANG(?label) = 'en') }.
                OPTIONAL { ?team_uri <http://dbpedia.org/property/fullname> ?altname . FILTER(LANG(?altname) = 'en') }.
              }
            }
            ORDER BY DESC(?years)"
    solutions = DBPEDIA.query(sparql)
    # do uniq
    Hash[solutions.reverse.map { |sol| [sol.career_station_uri.to_s, sol] }].values.reverse
  end

  def write_to_xml
    graph = RDF::Graph.load RDF_TTL_FILE
    RDF::RDFXML::Writer.open((Rails.root.join 'doc', 'example.rdf').to_s, format: :xml) do |writer|
      writer << graph
    end
  end

end
