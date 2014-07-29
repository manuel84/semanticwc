# @author Manuel Dudda <dudda@redpeppix.de>
module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'db', 'worldcup.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)
  DBPEDIA = SPARQL::Client.new('http://de.dbpedia.org/sparql')

  def get_multi_stage_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{RDF.type}> <#{PREFIX::BBCSPORT}MultiStageCompetition> }")
    solutions = QUERYABLE.query(sparql)
  end

  # returns all matches filtered by a specific filter.
  # Each match contains
  # uri,
  # homeCompetitor,
  # homeCompetitor_uri,
  # awayCompetitor,
  # awayCompetitor_uri,
  # round,
  # round_uri
  # venue    (todo)
  # venue_uri
  #
  # @param filter_uri [String] the filter type, can be a group, day, stadium, team or none filter
  # @return [RDF::Query::Solutions] the array-similar object of RDF::Query::Solution
  def get_matches(filter_uri)
    optional_filter = if filter_uri
                        ""
                      else
                        ""
                      end
    sparql = SPARQL.parse("
              SELECT ?uri ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri ?venue ?venue_uri ?time
              WHERE {
                ?uri <#{RDF.type}> <#{PREFIX::BBCSPORT}Match> .
                ?uri <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
                ?homeCompetitor_uri <#{RDF::RDFS.label}> ?homeCompetitor .
                ?uri <#{PREFIX::BBCSPORT}awayCompetitor> ?awayCompetitor_uri .
                ?awayCompetitor_uri <#{RDF::RDFS.label}> ?awayCompetitor .


                ?uri <#{PREFIX::BBCSPORT}Venue> ?venue_uri .
                ?uri <http://purl.org/NET/c4dm/event.owl#time> ?time
                #{optional_filter}
              }
              ")
    solutions = QUERYABLE.query(sparql)
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
    optional_filter = lang_filter ? "FILTER ( LANG(?label) = 'de')" : ''
    sparql = "SELECT ?uri ?label ?name ?image_url ?thumbnail_url ?abstract
        WHERE {
                ?uri <#{RDF::RDFS.label}> ?label .
                <#{uri}> <#{RDF::RDFS.label}> ?label .
                OPTIONAL {
                  <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url .
                  <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url .
                  <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract .
                  <#{uri}> <http://xmlns.com/foaf/0.1/name> ?name .
                  FILTER ( LANG(?name) = 'de' )
                }
                #{optional_filter}
                }"
    solution = DBPEDIA.query(sparql).first
    solution ||= get_team(uri, false) if lang_filter
  end

  # return a collection of player from a national team given by the team uri
  # A player contains
  # uri,
  # name
  # @param uri [String] the uri of the team
  # @return [RDF::Query::Solutions] the players
  def get_players_for_team(uri)
    ['Jefferson',
     'César, Júlio',
     'Victor',
     'Alves, Dani',
     'Silva, Thiago',
     'Luiz, David',
     'Marcelo',
     'Dante',
     'Maxwell',
     'Henrique',
     'Maicon',
     'Fernandinho',
     'Paulinho',
     'Oscar',
     'Ramires',
     'Gustavo, Luiz',
     'Hernanes',
     'Willian',
     'Hulk',
     'Fred',
     'Neymar',
     'Bernard',
     'Jô']
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
          ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name}\"@en .
          ?player_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerPlayer> .
          ?player_uri <http://dbpedia.org/ontology/team> <#{team_uri}> .
          ?player_uri <http://dbpedia.org/property/birthDate> ?birth_date .
          FILTER(?birth_date > \"19700101\"^^xsd:date)
        }"
    solutions = DBPEDIA.query sparql
    result = case solutions.count
               when 0 # fallback
                 sparql = "SELECT DISTINCT ?player_uri ?team_uri
                WHERE {
                  ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name}\"@en .
                  ?player_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerPlayer> .
                  ?player_uri <http://dbpedia.org/property/birthDate> ?birth_date .
                  FILTER(?birth_date > \"19700101\"^^xsd:date)
                }"
                 solutions = DBPEDIA.query sparql
                 solutions.first
               when 1
                 solutions.first
               else
                 puts solutions.count
                 solutions.first
             end
    result.player_uri.to_s if result
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
    sparql = "SELECT DISTINCT ?uri ?fullname ?position ?birth_date ?current_club_uri ?current_club ?image_url ?thumbnail_url ?abstract
           WHERE {
             <#{uri}> <http://dbpedia.org/property/fullname> ?fullname .
             OPTIONAL {<#{uri}> <http://dbpedia.org/ontology/position> ?position .
             <#{uri}> <http://dbpedia.org/property/birthDate> ?birth_date .
             <#{uri}> <http://dbpedia.org/property/currentclub> ?current_club_uri .
             ?current_club_uri <#{RDF::RDFS.label}> ?current_club .
             <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url .
             <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url .
             <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract .
            FILTER ( LANG(?current_club) = 'de' && LANG(?abstract) = 'de' )
}

           }"
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

  end

  # return a trainer given by a specific uri.
  # A trainer contains
  # uri,
  # firstName         FOAF
  # firstName_uri     FOAF
  # familyName        FOAF
  # familyName_uri    FOAF
  # TODO...
  # @param uri [String] the uri of the trainer
  # @return [RDF::Query::Solution] the trainer
  def get_trainer_for_team(uri)
    ['Luiz Felipe Scolari', 'Joachim Löw'].last
  end

  def get_trainer(uri)
    sparql = "SELECT DISTINCT ?fullname ?birth_date ?image_url ?thumbnail_url ?abstract
           WHERE {
             <#{uri}> <http://dbpedia.org/property/fullname> ?fullname .
             OPTIONAL { <#{uri}> <http://dbpedia.org/property/birthDate> ?birth_date .
             <#{uri}> <http://xmlns.com/foaf/0.1/depiction> ?image_url .
             <#{uri}> <http://dbpedia.org/ontology/thumbnail> ?thumbnail_url .
             <#{uri}> <http://dbpedia.org/ontology/abstract> ?abstract .
            FILTER ( LANG(?abstract) = 'de' )
}

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
                 puts solutions.count
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

  end

  # return all team stations with time period a player participated in descendant order given by a specific uri.
  # A team station contains
  # uri,
  # TODO...
  # @param uri [String] the uri of the player
  # @return [RDF::Query::Solutions] the team stations
  def get_trainer_team_stations(uri)

  end

  def write_to_xml
    graph = RDF::Graph.load RDF_TTL_FILE
    RDF::RDFXML::Writer.open((Rails.root.join 'doc', 'example.rdf').to_s, format: :xml) do |writer|
      writer << graph
    end
  end

  def img_url(sol)
    if sol && sol.has_attributes?(['image_url'])
      sol.image_url
    else
      lorem_img
    end
  end

end
