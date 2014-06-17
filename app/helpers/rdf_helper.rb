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

  def tmp_all_teams
    [
        "Algerien",
        "Argentinien",
        "Australien",
        "Belgien",
        "Bosnien und Herzegowina",
        "Brasilien",
        "Chile",
        "Costa Rica",
        "Deutschland",
        "Ecuador",
        "Elfenbeinküste",
        "England",
        "Frankreich",
        "Ghana",
        "Griechenland",
        "Honduras",
        "Iran",
        "Italien",
        "Japan",
        "Kamerun",
        "Kolumbien",
        "Korea Republik",
        "Kroatien",
        "Mexiko",
        "Niederlande",
        "Nigeria",
        "Portugal",
        "Russland",
        "Schweiz",
        "Spanien",
        "Uruguay",
        "USA",
        "Algerien",
        "Elfenbeinküste",
        "Ghana",
        "Kamerun",
        "Nigeria",
        "Australien",
        "Iran",
        "Japan",
        "Korea Republik",
        "Belgien",
        "Bosnien und Herzegowina",
        "Deutschland",
        "England",
        "Frankreich",
        "Griechenland",
        "Italien",
        "Kroatien",
        "Niederlande",
        "Portugal",
        "Russland",
        "Schweiz",
        "Spanien",
        "Costa Rica",
        "Honduras",
        "Mexiko",
        "USA",
        "Argentinien",
        "Brasilien",
        "Chile",
        "Ecuador",
        "Kolumbien",
        "Uruguay"

    ]
  end

  def tmp_all_stadiums
    [
        "Belo Horizonte",
        "Brasília",
        "Cuiabá",
        "Curitiba",
        "Fortaleza",
        "Manaus",
        "Natal",
        "Porto Alegre",
        "Recife",
        "Rio De Janeiro",
        "Salvador",
        "São Paulo"
    ]
  end
end
