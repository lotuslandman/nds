class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams
end
