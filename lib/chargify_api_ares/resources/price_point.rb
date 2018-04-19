module Chargify
  class PricePoint < Base
    include ResponseHelper

    self.prefix = '/components/:component_id/'

    def self.price_points(component_id)
      find(:all, :params => {:component_id => component_id})
    end
  end
end
