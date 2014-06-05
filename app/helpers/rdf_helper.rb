module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'doc', 'example.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)

  def get_multi_stage_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{PREFIX::RDF}type> <#{PREFIX::BBCSPORT}MultiStageCompetition> }")
    solutions = QUERYABLE.query(sparql)
  end

  def get_matches(filter_type,filter_value)

  end

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
    solutions = QUERYABLE.query(sparql).first
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
