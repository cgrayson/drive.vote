class Campaign < ApplicationRecord
  belongs_to :election
  
  validates_presence_of :slug, :name
  validates_uniqueness_of :slug, :name
end
