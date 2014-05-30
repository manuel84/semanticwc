module RdfHelper
  RDF_TTL_FILE = (Rails.root.join 'doc', 'example.ttl').to_s
  QUERYABLE = RDF::Repository.load(RDF_TTL_FILE)

  def get_divisional_competitions
    sparql = SPARQL.parse("SELECT * WHERE { ?s <#{PREFIX::RDF}type> <#{PREFIX::BBCSPORT}DivisionalCompetition> }")
    solutions = QUERYABLE.query(sparql)
  end
end
