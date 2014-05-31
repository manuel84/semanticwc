require 'spec_helper'
describe RdfHelper do
  describe "#ttl file" do
    it "Fußball-Weltmeisterschaft_2014 has as MultiStageCompetition" do
      divisional_competitions = helper.get_multi_stage_competitions
      divisional_competitions.filter { |solution| solution.s.eql?(RDF::URI.new "http://de.dbpedia.org/page/Fu%C3%9Fball-Weltmeisterschaft_2014") }
      divisional_competitions.should_not be_empty
    end
  end
end