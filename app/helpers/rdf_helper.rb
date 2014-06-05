module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'doc', 'example.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)

  def get_multi_stage_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{PREFIX::RDF}type> <#{PREFIX::BBCSPORT}MultiStageCompetition> }")
    solutions = QUERYABLE.query(sparql)
  end


  def get_game uri
    sparql = SPARQL.parse("SELECT ?homeCompetitor ?awayCompetitor ?round
    WHERE {
            <#{uri}> <#{PREFIX::BBCSPORT}homeCompetitor> ?home .
            ?home <#{PREFIX::RDFS}label> ?homeCompetitor .
            <#{uri}> <#{PREFIX::BBCSPORT}awayCompetitor> ?away .
            ?away <#{PREFIX::RDFS}label> ?awayCompetitor .
            ?rnd <#{PREFIX::BBCSPORT}hasMatch> <#{uri}> .
            ?rnd <#{PREFIX::RDFS}label> ?round .
            }")
    solutions = QUERYABLE.query(sparql).first
  end

  def __get_game2(uri)
    sparql = SPARQL.parse("SELECT * WHERE { <#{uri}> ?p ?o .}")
    solutions = QUERYABLE.query(sparql)
  end

  def __round_from_game(uri)
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{PREFIX::BBCSPORT}hasMatch> <#{uri}> .}")
    solutions = QUERYABLE.query(sparql)
  end

  def write_to_xml
    graph = RDF::Graph.load RDF_TTL_FILE
    RDF::RDFXML::Writer.open((Rails.root.join 'doc', 'example.rdf').to_s, format: :xml) do |writer|
      writer << graph
    end
  end
end
