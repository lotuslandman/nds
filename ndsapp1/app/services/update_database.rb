ds_1 = DeltaStream.find_by_id(1)
ds_1 ||= DeltaStream.create(id: 1, frequency_minutes: 3, delta_reachback: 6)  
ds_1.create_pretty_response_file_and_fill_database
    
  #class DatabaseServices
#    def update_database_for_all_streams
    
#    @delta_stream_2 = DeltaStream.find_by_id(2)
#    @delta_stream_2 ||= DeltaStream.create(id: 2, frequency_minutes: 3, delta_reachback: 6)  
#    @delta_stream_2.fill_database
    
#    @delta_stream_3 = DeltaStream.find_by_id(3)
#    @delta_stream_3 ||= DeltaStream.create(id: 3, frequency_minutes: 3, delta_reachback: 6)  
#    @delta_stream_3.fill_database
#  end

#end
