require 'spec_helper'
describe RdfHelper do
  describe "#ttl file" do
    it "Fußball-Weltmeisterschaft_2014 has as MultiStageCompetition" do
      divisional_competitions = helper.get_multi_stage_competitions
      divisional_competitions.filter { |solution| solution.s.eql?(RDF::URI.new "http://de.dbpedia.org/page/Fußball-Weltmeisterschaft_2014") }
      divisional_competitions.should_not be_empty
      helper.write_to_xml
    end
  end

  it "Koratien - Brasilien belongs to group A" do
    bra_cro = helper.get_match "#{PREFIX::WIKI}Fußball-Weltmeisterschaft_2014/Gruppe_A#Brasilien_.E2.80.93_Kroatien"
    bra_cro.round.to_s.should be_eql("Gruppe A")
  end

end