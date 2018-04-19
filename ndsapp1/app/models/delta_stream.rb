class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy
end
