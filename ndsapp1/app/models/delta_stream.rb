class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  def extract_date(fnp)
      File.basename(fnp).split('_')[1].split('.')[0].sub('T', ' ')+' UTC'
  end
  
  def get_filenames
    stream_number = self.id.to_s
    Dir.glob("/home/scott/dev/nds/stream_files/stream_#{stream_number.to_s}_files/2019-3/files_delta/*").sort.collect do |fnp|
      '../files_delta/'+File.basename(fnp)  # have to back out of rails directory with ../
    end
  end
  
  def fill_database
    path = "/home/scott/dev/nds/ndsapp1/llog.txt"

    request_type  = :delta
    file_name_array = get_filenames.sort.each do |file_name|
      file_name.split("delta")[2].split('.')[0][1..-1]
    end
    date_array_from_filesystem = file_name_array.collect do |fn|
      extract_date(fn)
    end
    date_array_from_database  = DeltaRequest.all.collect { |dr| dr.request_time.to_s}
    dates_to_get = date_array_from_filesystem - date_array_from_database
    File.open(path, 'w') { |rf| rf.puts "Topping of database with #{dates_to_get.size} delta_requests"} 
    loop = 0
    dates_to_get.collect do |file_name|
      File.open(path, 'a') { |rf| rf.puts "#{loop}: getting #{file_name}"} 
      @delta_request = self.delta_requests.create()  # create new delta_request from this delta_stream
      @delta_request.create_pretty_response_file(file_name)
      loop += 1
    end
  end

#  def self.update_database
  def self.update_database_for_all_streams
#    @delta_stream_1 = DeltaStream.find_by_id(1) ||= DeltaStream.create(id: 1, frequency_minutes: 3, delta_reachback: 6) 
#    @delta_stream_1.fill_database
#    @delta_stream_2 = DeltaStream.find_by_id(2) ||= DeltaStream.create(id: 2, frequency_minutes: 3, delta_reachback: 6) 
#    @delta_stream_2.fill_database

    @delta_stream_1 = DeltaStream.find_by_id(1)
    @delta_stream_1 ||= DeltaStream.create(id: 1, frequency_minutes: 3, delta_reachback: 6)  
    @delta_stream_1.fill_database
    
    @delta_stream_3 = DeltaStream.find_by_id(3)
    @delta_stream_3 ||= DeltaStream.create(id: 3, frequency_minutes: 3, delta_reachback: 6)  
    @delta_stream_3.fill_database
  end

  def delta_request_chart(st, en, scenario)
    notams_all = []
    notams_flt = []
    # builds array of hashes where index is to be grouped
    self.delta_requests.collect { |dr| notams_all << {dr.request_time => dr.duration}}
    #    This commented line was original showing number of notams instead of request duration
    #    DeltaRequest.all.collect { |dr| notams_all << {dr.request_time => dr.notams.size}}
    self.delta_requests.collect { |dr| notams_flt << {dr.request_time => (dr.scenario_notams(scenario).size)}}
    #    notams_all_1 = notams_all[50..60]
    #    notams_flt_1 = notams_flt[50..60]
    notams_all_1 = notams_all[st..en]
    notams_flt_1 = notams_flt[st..en]
    # takes array of hashes and makes hash, flattening allong hash keys
    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    all_notams_w_filtered = [
      {name: "Blue Filtered Notams", data: notams_all_2},
      {name: "Red Filtered Notams", data: notams_flt_2}
    ]
  end

  
end
