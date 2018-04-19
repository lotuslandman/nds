class CreateDeltaRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :delta_requests do |t|
      t.datetime :request_time
      t.references :delta_stream, foreign_key: true

      t.timestamps
    end
  end
end
