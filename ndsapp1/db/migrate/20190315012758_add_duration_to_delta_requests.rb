class AddDurationToDeltaRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :delta_requests, :duration, :float
    add_column :delta_requests, :start_time, :datetime
    add_column :delta_requests, :end_time, :datetime
    add_column :delta_requests, :parseable, :boolean

    add_index :delta_requests, :start_time
  end
end
