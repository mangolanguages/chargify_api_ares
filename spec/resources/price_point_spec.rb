require 'spec_helper'

describe Chargify::PricePoint, :fake_resource do
  context 'price_points' do
    let(:component_id) { 5 }
    let(:price_points) do
      [
        {
          :price_point => { :id => 99, :component_id => component_id, :prices => ["default", "promo"] }
        }
      ]
    end
    before(:each) do
      FakeWeb.register_uri(:get, "#{test_domain}/components/#{component_id}/price_points.xml", :body => price_points.to_xml(root: "price_points"))
    end

    it "returns the price_points belonging to the component" do
      response = Chargify::PricePoint.price_points(component_id)
      expect(response.first.attributes).to eql({"id"=>99, "component_id"=>5, "prices"=>["default", "promo"]})
    end
  end
end
