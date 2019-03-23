require 'time'
class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  def extract_date(fnp)
      File.basename(fnp).split('_')[1].split('.')[0].sub('T', ' ')+' UTC'
  end
  
  def get_filenames
    stream_number = self.id.to_s
    out = Dir.glob("/home/scott/dev/nds/stream_files/stream_#{stream_number.to_s}_files/2019-3/files_delta/*").sort.collect do |fnp|
      '../files_delta/'+File.basename(fnp)  # have to back out of rails directory with ../
    end
  end
  
#    File.open(path, 'w') { |rf| rf.puts "Top DB for DS #{self.id} with #{dates_to_get.size} (#{date_array_from_filesystem.size}-#{date_array_from_database.size}) delta_requests"}

  def create_pretty_response_file_and_fill_database
    path = "/home/scott/dev/nds/ndsapp1/llog.txt"
    request_type  = :delta
    # go into the filesystem ".../.../files_delta/" and find all responses  WARNING: get_filenames hardcoded to March 2019
    file_name_array = get_filenames.sort.each do |file_name|
      file_name.split("delta")[2].split('.')[0][1..-1]
    end
    date_array_from_filesystem = file_name_array.collect do |fn|
      extract_date(fn)
    end
    # go into the database to find all this streams requests
    date_array_from_database  = self.delta_requests.collect { |dr| dr.end_time.to_s}  # WARNING!!! why does dr.request_time still work????
    dates_to_get_full = date_array_from_filesystem - date_array_from_database
    binding.pry
    dates_to_get_full_sort = dates_to_get_full.sort
    puts "dates_to_get_full_sort #{dates_to_get_full_sort.size} = date_array_from_filesystem #{date_array_from_filesystem.size} - date_array_from_database = #{date_array_from_database.size}"
    if dates_to_get_full_sort.size > 105   # limit chunk to put in database to 55
      dates_to_get = dates_to_get_full_sort[-5..-1]
    else
      dates_to_get = dates_to_get_full_sort
    end
    puts "Number of dates to be put in the database: #{dates_to_get.size}"
    loop = 0
    dates_to_get.collect do |file_name|
#      puts "#{loop}: getting #{file_name}"
      @delta_request = self.delta_requests.create()  # create new delta_request from this delta_stream
      begin
        @delta_request.set_parseable_bool(true)
        @delta_request.parse_response_time_save_pretty_store_in_db(file_name)
      rescue
        @delta_request.set_parseable_bool(false)
        puts "filename = #{file_name} - failure"
      end
      loop += 1
    end
  end

  def column_chart_data(start_date_string, end_date_string, scenario, y_axis)
    notams_all = []
    notams_flt = []
    # builds array of hashes where index is to be grouped
    start_time = Time.parse(start_date_string)
    end_time = Time.parse(end_date_string)
    self.delta_requests.collect do |dr|
      if (dr.start_time < end_time) and (dr.start_time > start_time)
        notams_all << {dr.end_time => dr.duration}
#        notams_all << {dr.end_time => dr.notams.size}
      end
    end
#    self.delta_requests.collect { |dr| notams_flt << {dr.end_time => (dr.scenario_notams(scenario).size)}}
    
#    self.delta_requests.collect { |dr| notams_flt << {dr.end_time => dr.duration}}
#    if y_axis == "response_time"
#    elsif y_axis == "number_of_notams"
    #    end
    notams_all_1 = notams_all
#    notams_flt_1 = notams_flt[-7..-1]
    # takes array of hashes and makes hash, flattening allong hash keys
    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#    all_notams_w_filtered = [
#      {name: "Blue Filtered Notams", data: notams_all_2},
#      {name: "Red Filtered Notams", data: notams_flt_2}
#    ]
  end

  
end
