# @author Manuel Dudda <manueldudda@redpeppix.de>
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
  # - uri
  # - homeCompetitor
  # - homeCompetitor_uri
  # - awayCompetitor
  # - awayCompetitor_uri
  # - round
  # - round_uri
  # - venue_uri
  # - time
  # - homeCompetitorGoals (if present)
  # - awayCompetitorGoals (if present)
  #
  # @param filter_uri [String] the filter type, can be a group, day, stadium, team or none filter
  # @return [Array<RDF::Query::Solution>, String] Array of matches and the calculated filter_type
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
                ?round_uri <#{PREFIX::BBCSPORT}hasMatch> ?uri .
                ?round_uri <#{RDF::RDFS.label}> ?round .
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

  # returns all teams.
  # The teams will be ordered by name ascending .
  # Each team contains
  # - uri
  # - name
  #
  # @return [Array<RDF::Query::Solution>] Array of teams
  def get_teams
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?name
                    WHERE {
                      ?group_uri <http://www.bbc.co.uk/ontologies/sport/hasCompetitor> ?uri .
                      ?uri <#{RDF::RDFS.label}> ?name .
                    }
                  ORDER BY ASC(?name)
            ")
    solutions = QUERYABLE.query(sparql)
  end

  # returns all stadiums.
  # @see #get_stadium for content of a stadium
  #
  # @return [Array<RDF::Query::Solution>] Array of stadiums
  def get_stadiums
    sparql = SPARQL.parse('SELECT DISTINCT ?uri
                WHERE {
                  ?match <http://www.bbc.co.uk/ontologies/sport/Venue> ?uri .
                }')
    results = QUERYABLE.query(sparql).map { |sol| get_stadium(sol.uri) }
  end

  # returns all groups.
  # The groups will be ordered by label ascending .
  # Each group contains
  # - uri
  # - label
  #
  # @return [Array<RDF::Query::Solution>] Array of groups
  def get_groups
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label
                    WHERE {
                      ?uri <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?match_uri .
                      ?uri <#{RDF::RDFS.label}> ?label .
                    }
                ORDER BY ASC(?label)
          ")
    results = QUERYABLE.query(sparql)
  end

  # returns all rounds.
  # The groups will be ordered by time ascending .
  # Each rounds contains
  # - uri
  # - label
  # - time
  #
  # @return [Array<RDF::Query::Solution>] Array of rounds
  def get_rounds
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label ?time
                      WHERE {
                        {
                          ?uri <#{RDF.type}> <http://www.bbc.co.uk/ontologies/sport/KnockoutCompetition> .
                          ?uri <#{RDF::RDFS.label}> ?label .
                          ?uri <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?match_uri .
                          ?match_uri <http://purl.org/NET/c4dm/event.owl#time> ?time .
                        }
                        UNION
                        {
                          ?uri <http://www.bbc.co.uk/ontologies/sport/hasMatch> ?match_uri .
                          ?uri <#{RDF::RDFS.label}> ?label .
                          ?match_uri <http://purl.org/NET/c4dm/event.owl#time> ?time .
                        }
                      }
                  ORDER BY ASC(?time)
            ")
    results = QUERYABLE.query(sparql)
  end

  # returns all matchdays. Dates without matches are filtered.
  # The days will be ordered by ascending .
  #
  # @return [Array<Date>] the days
  def get_days
    sparql = SPARQL.parse("SELECT DISTINCT ?time
                    WHERE {
                      ?match <#{RDF.type}> <http://www.bbc.co.uk/ontologies/sport/Match> .
                      ?match <http://purl.org/NET/c4dm/event.owl#time> ?time .
                    }")
    results = QUERYABLE.query(sparql).map { |sol| Date.parse(sol.time.to_s) }.uniq
  end

  # returns a match given by a specific uri.
  # A match contains
  # - uri
  # - homeCompetitor
  # - homeCompetitor_uri
  # - awayCompetitor
  # - awayCompetitor_uri
  # - round
  # - round_uri
  # - venue_uri
  # - time
  # - homeCompetitorGoals (if present)
  # - awayCompetitorGoals (if present)
  #
  # @example
  #   match = get_match "http://cs.hs-rm.de/~mdudd001/semanticwc/ALG_RUS"
  #   #=>  #<RDF::Query::Solution:0x8090bf98({:uri=>#<RDF::URI:0x80a26a90 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/ALG_RUS>,
  #           :awayCompetitorGoals=>#<RDF::Literal::Int:0x8196a2a4("1"^^<http://www.w3.org/2001/XMLSchema#int>)>,
  #           :homeCompetitorGoals=>#<RDF::Literal::Int:0x82b7b254("1"^^<http://www.w3.org/2001/XMLSchema#int>)>,
  #           :homeCompetitor_uri=>#<RDF::URI:0x82b8a22c URI:http://dbpedia.org/resource/Algeria_national_football_team>,
  #           :homeCompetitor=>#<RDF::Literal:0x848cce34("Algeria")>,
  #           :awayCompetitor_uri=>#<RDF::URI:0x81976bbc URI:http://dbpedia.org/resource/Russia_national_football_team>,
  #           :awayCompetitor=>#<RDF::Literal:0x838d673c("Russia")>,
  #           :round_uri=>#<RDF::URI:0x80ec405c URI:http://cs.hs-rm.de/~mdudd001/semanticwc/Group_H>, :round=>#<RDF::Literal:0x80e941b8("Group H")>,
  #           :venue_uri=>#<RDF::URI:0x8197f758 URI:http://dbpedia.org/resource/Arena_da_Baixada>,
  #           :time=>#<RDF::Literal::DateTime:0x82bb213c("2014-06-26T17:00:00.000-03:00"^^<http://www.w3.org/2001/XMLSchema#dateTime>)>})>
  #
  # @param uri [String] the uri of the match
  # @return [RDF::Query::Solution] the match
  def get_match(uri)
    sparql = SPARQL.parse("SELECT ?uri ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri ?venue_uri ?time ?homeCompetitorGoals ?awayCompetitorGoals
    WHERE {
            ?uri <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
            <#{uri}> <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
            ?homeCompetitor_uri <#{RDF::RDFS.label}> ?homeCompetitor .
            <#{uri}> <#{PREFIX::BBCSPORT}awayCompetitor> ?awayCompetitor_uri .
            ?awayCompetitor_uri <#{RDF::RDFS.label}> ?awayCompetitor .
            ?round_uri <#{PREFIX::BBCSPORT}hasMatch> <#{uri}> .
            ?round_uri <#{RDF::RDFS.label}> ?round .
            ?uri <#{PREFIX::BBCSPORT}Venue> ?venue_uri .
            ?uri <http://purl.org/NET/c4dm/event.owl#time> ?time .
            OPTIONAL { ?uri <http://www.bbc.co.uk/ontologies/sport/homeCompetitorGoals> ?homeCompetitorGoals . }.
            OPTIONAL { ?uri <http://www.bbc.co.uk/ontologies/sport/awayCompetitorGoals> ?awayCompetitorGoals . }.
            }")
    solution = QUERYABLE.query(sparql).first
  end

  # returns a group given by a specific uri.
  # A group contains
  # - uri
  # - label
  #
  # @example
  #   group = get_group "http://cs.hs-rm.de/~mdudd001/semanticwc/Group_A"
  #   => #<RDF::Query::Solution:0x86029dd4({:uri=>#<RDF::URI:0x8386387c URI:http://cs.hs-rm.de/~mdudd001/semanticwc/Group_A>,
  #         :label=>#<RDF::Literal:0x8384fbd8("Group A")>})>
  #
  # @param uri [String] the uri of the group
  # @return [RDF::Query::Solution] the group
  def get_group(uri)
    sparql = SPARQL.parse("SELECT ?uri ?label
      WHERE {
              ?uri <#{RDF::RDFS.label}> ?label .
              <#{uri}> <#{RDF::RDFS.label}> ?label .
              }")
    solution = QUERYABLE.query(sparql).first
  end

  # returns all goals corresponding to a match by the given uri
  # A group contains
  # - uri
  # - label
  #
  # @example
  #   get_goals "http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER"
  #   => [#<RDF::Query::Solution:0x860c679c({:goal_uri=>#<RDF::URI:0x831af3c8 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_3bhpwas9e4b6>,
  #         :player_uri=>#<RDF::URI:0x831a2678 URI:http://dbpedia.org/resource/Thomas_M%C3%BCller>, :player=>#<RDF::Literal:0x83bc086c("Müller")>,
  #         :factor=>#<RDF::Literal:0x83197534("goal")>,
  #         :time_uri=>#<RDF::URI:0x831775f4 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_od8u0wuqirmt>,
  #         :time=>#<RDF::Literal::Int:0x832f6920("11"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860cb904({:goal_uri=>#<RDF::URI:0x80fd098c URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_t68cap7hb3gh>,
  #         :player_uri=>#<RDF::URI:0x80fb4a84 URI:http://dbpedia.org/resource/Miroslav_Klose>, :player=>#<RDF::Literal:0x828da5e0("Klose")>,
  #         :factor=>#<RDF::Literal:0x80fa0e94("goal")>,
  #         :time_uri=>#<RDF::URI:0x80f45f1c URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_byzvwsirjwqb>,
  #         :time=>#<RDF::Literal::Int:0x8333772c("23"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860c61d4({:goal_uri=>#<RDF::URI:0x83112eec URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_i3zsj16i95y8>,
  #         :player_uri=>#<RDF::URI:0x831037a8 URI:http://dbpedia.org/resource/Toni_Kroos>, :player=>#<RDF::Literal:0x80a567e0("Kroos")>,
  #         :factor=>#<RDF::Literal:0x830f7ed0("goal")>,
  #         :time_uri=>#<RDF::URI:0x830d6b90 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_01slv8jy3mzy>,
  #         :time=>#<RDF::Literal::Int:0x838237a4("24"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860c64b8({:goal_uri=>#<RDF::URI:0x8315edd8 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_d0led6akvjgf>,
  #         :player_uri=>#<RDF::URI:0x831522cc URI:http://dbpedia.org/resource/Toni_Kroos>, :player=>#<RDF::Literal:0x80a567e0("Kroos")>,
  #         :factor=>#<RDF::Literal:0x831472a0("goal")>,
  #         :time_uri=>#<RDF::URI:0x831261f4 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_ols7mjl5ozbj>,
  #         :time=>#<RDF::Literal::Int:0x832d60d0("26"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860cbecc({:goal_uri=>#<RDF::URI:0x830c64ac URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_kuidlkio4jfc>,
  #         :player_uri=>#<RDF::URI:0x830b6480 URI:http://dbpedia.org/resource/Sami_Khedira>, :player=>#<RDF::Literal:0x83b017b4("Khedira")>,
  #         :factor=>#<RDF::Literal:0x830abd14("goal")>,
  #         :time_uri=>#<RDF::URI:0x8308b67c URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_0zt3w2rmqtpk>,
  #         :time=>#<RDF::Literal::Int:0x833c7804("29"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860cb620({:goal_uri=>#<RDF::URI:0x80f1d7c4 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_u28m6giqlph2>,
  #         :player_uri=>#<RDF::URI:0x80efdec4 URI:http://dbpedia.org/resource/Andr%C3%A9_Sch%C3%BCrrle>,
  #         :player=>#<RDF::Literal:0x83372e58("Schürrle")>,
  #         :factor=>#<RDF::Literal:0x80ee516c("goal")>,
  #         :time_uri=>#<RDF::URI:0x80e98aec URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_2v07xr0lohba>,
  #         :time=>#<RDF::Literal::Int:0x833b6284("69"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860cbbe8({:goal_uri=>#<RDF::URI:0x8306feb8 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_otyy0lotrj3e>,
  #         :player_uri=>#<RDF::URI:0x8305e730 URI:http://dbpedia.org/resource/Andr%C3%A9_Sch%C3%BCrrle>,
  #         :player=>#<RDF::Literal:0x83372e58("Schürrle")>,
  #         :factor=>#<RDF::Literal:0x83053e0c("goal")>,
  #         :time_uri=>#<RDF::URI:0x80ff15d8 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_2yb8uyxkmj9d>,
  #         :time=>#<RDF::Literal::Int:0x83397924("79"^^<http://www.w3.org/2001/XMLSchema#int>)>})>,
  #       #<RDF::Query::Solution:0x860c6a80({:goal_uri=>#<RDF::URI:0x831fe874 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Goal_17nr98dozoes>,
  #         :player_uri=>#<RDF::URI:0x831ebddc URI:http://dbpedia.org/resource/Oscar_(footballer_born_1991)>,
  #         :player=>#<RDF::Literal:0x828de3fc("Oscar")>,
  #         :factor=>#<RDF::Literal:0x831e2e30("goal")>,
  #         :time_uri=>#<RDF::URI:0x831c2784 URI:http://cs.hs-rm.de/~mdudd001/semanticwc/BRA_GER_Time_0fxn56muoech>,
  #         :time=>#<RDF::Literal::Int:0x83805a10("90"^^<http://www.w3.org/2001/XMLSchema#int>)>})>]
  #
  # @param uri [String] the uri of the match
  # @return [Array<RDF::Query::Solution>] Array of goals
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
    solutions = QUERYABLE.query(sparql).sort { |g1, g2| g1.time.to_s.gsub('+', '.').to_f <=> g2.time.to_s.gsub('+', '.').to_f }
  end

  # guess a team uri by a given team name
  #
  # @param name [String] the name of the county
  # @return [String] the uri of the national footbll team in dbpedia
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

  # return all players of a team given by the uri
  # A player contains
  # - uri
  # - label
  # - team_uri
  # - team
  #
  # @param uri [String] the uri of the team
  # @return [Array<RDF::Query::Solution>] Array of the players
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

  # @deprecated
  def tmp_get_player(uri)
    sparql = SPARQL.parse("SELECT DISTINCT ?uri ?label ?team_uri ?team
          WHERE {
            <#{uri}> <#{RDF::RDFS.label}> ?label .
            <#{uri}> <http://purl.org/hpi/soccer-voc/playsFor> ?team_uri .
            ?team_uri <#{RDF::RDFS.label}> ?team .
          }")
    solutions = QUERYABLE.query(sparql).first
  end

  # guess a player uri by a given name and the uri of the team
  #
  # @param name [String] the name of the player
  # @return [String, nil] the uri player at dbpedia
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
          { ?player_uri <http://xmlns.com/foaf/0.1/givenName> \"#{name}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/fullname> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/givenName> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/surname> \"#{name.split(' ').first}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/name> \"#{name.split(' ').last}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/fullname> \"#{name.split(' ').last}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/surname> \"#{name.split(' ').last}\"@en . }
          UNION
          { ?player_uri <http://xmlns.com/foaf/0.1/givenName> \"#{name.split(' ').last}\"@en . }
          ?player_uri <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedia.org/ontology/SoccerPlayer> .
          ?player_uri <http://dbpedia.org/property/nationalteam> <#{team_uri}> .
          ?player_uri <http://dbpedia.org/property/nationalteam> ?team_uri
          OPTIONAL { ?player_uri <http://dbpedia.org/property/nationalcaps> ?caps }.
          OPTIONAL { ?player_uri <http://dbpedia.org/property/nationalgoals> ?goals }.
          ?player_uri <http://dbpedia.org/property/birthDate> ?birth_date .
          FILTER(?birth_date > \"19700101\"^^xsd:date)
        }
        ORDER BY DESC(?caps) DESC(?goals)"
    solutions = DBPEDIA.query sparql
    result = solutions.first
    result.present? ? result.player_uri.to_s : nil
  end

  # returns a player given by the uri.
  # A player contains
  # - uri
  # - name
  # - surname (if present)
  # - givenName (if present)
  # - fullname (if present)
  # - position (if present)
  # - birth_date (if present)
  # - current_club_uri (if present)
  # - current_club (if present)
  # - image_url (if present)
  # - thumbnail_url (if present)
  # - abstract (if present)
  # - team (if present)
  # - team_uri (if present)
  # - caps (if present)
  # - goals (if present)
  #
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

  # returns a stadium given by the uri.
  # A stadium contains
  # - uri
  # - name
  # - city_uri
  # - city
  # - population
  # - lat
  # - long
  # - capacity (if present)
  # - seatingCapacity (if present)
  # - image_url (if present)
  # - thumbnail_url (if present)
  # - abstract (if present)
  #
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

  # returns a trainer given by the uri.
  # A trainer contains
  # - uri
  # - name
  # - surname (if present)
  # - givenName (if present)
  # - fullname (if present)
  # - birth_date (if present)
  # - image_url (if present)
  # - thumbnail_url (if present)
  # - abstract (if present)
  # - team_uri (if present)
  #
  # @param uri [String] the uri of the stadium
  # @return [RDF::Query::Solution] the stadium
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

  # guess a trainer uri by a given name and uri of the team
  #
  # @param name [String] the name of the trainer
  # @return [String, nil] the uri trainer at dbpedia
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

  # return all team stations (only clubs) with time period a player participated in descendant order given by the uri of player.
  # A team_station contains
  # - uri
  # - career_station_uri
  # - years
  # - team_uri
  # - clubname (if present)
  # - name (if present)
  # - nickname (if present)
  # - label (if present)
  # - altname (if present)
  #
  # @param uri [String] the uri of the team_station
  # @return [RDF::Query::Solution] the team_station
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

  # return all team stations (only clubs) with time period a trainer participated in descendant order given by the uri of trainer.
  # A team_station contains
  # - uri
  # - career_station_uri
  # - years
  # - team_uri
  # - clubname (if present)
  # - name (if present)
  # - nickname (if present)
  # - label (if present)
  # - altname (if present)
  #
  # @param uri [String] the uri of the team_station
  # @return [RDF::Query::Solution] the team_station
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

end
