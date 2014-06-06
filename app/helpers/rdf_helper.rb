# @author Manuel Dudda <dudda@redpeppix.de>
module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'doc', 'example.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)

  def get_multi_stage_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{PREFIX::RDF}type> <#{PREFIX::BBCSPORT}MultiStageCompetition> }")
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
              SELECT ?uri ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri
              WHERE {
                ?uri <#{PREFIX::RDF}type> <#{PREFIX::BBCSPORT}Match> .
                #{optional_filter}
              }
              ")
    solutions = QUERYABLE.query(sparql)
  end

  # return a matches given a specific uri.
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
    sparql = SPARQL.parse("SELECT ?homeCompetitor ?homeCompetitor_uri ?awayCompetitor ?awayCompetitor_uri ?round ?round_uri
    WHERE {
            <#{uri}> <#{PREFIX::BBCSPORT}homeCompetitor> ?homeCompetitor_uri .
            ?homeCompetitor_uri <#{PREFIX::RDFS}label> ?homeCompetitor .
            <#{uri}> <#{PREFIX::BBCSPORT}awayCompetitor> ?awayCompetitor_uri .
            ?awayCompetitor_uri <#{PREFIX::RDFS}label> ?awayCompetitor .
            ?round_uri <#{PREFIX::BBCSPORT}hasMatch> <#{uri}> .
            ?round_uri <#{PREFIX::RDFS}label> ?round .
            }")
    solution = QUERYABLE.query(sparql).first
  end

  def get_team(uri)

  end

  def get_player(uri)

  end

  def get_stadium(uri)

  end

  def get_trainer(uri)

  end

  def write_to_xml
    graph = RDF::Graph.load RDF_TTL_FILE
    RDF::RDFXML::Writer.open((Rails.root.join 'doc', 'example.rdf').to_s, format: :xml) do |writer|
      writer << graph
    end
  end
end
