class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  def extract_date(fnp)
      File.basename(fnp).split('_')[1].split('.')[0].sub('T', ' ')+' UTC'
  end
  
  def get_filenames  #### !!!!! WARNING will need to modify to handle more than one stream (doing 3 for now for testing fntb)
    Dir.glob("/home/scott/dev/nds/stream_files/stream_3_files/2019-3/files_delta/*").sort.collect do |fnp|
      '../files_delta/'+File.basename(fnp)  # have to back out of rails directory with ../
    end
  end
  
  def fill_database
    request_type  = :delta
    file_name_array = get_filenames.sort.each do |file_name|
      file_name.split("delta")[2].split('.')[0][1..-1]
    end
    date_array_from_filesystem = file_name_array.collect do |fn|
      extract_date(fn)
    end
    date_array_from_database  = DeltaRequest.all.collect { |dr| dr.request_time.to_s}
    dates_to_get = date_array_from_filesystem - date_array_from_database
#    puts "Topping of database with #{dates_to_get.size} delta_requests"
    dates_to_get.collect do |file_name|
      @delta_request = self.delta_requests.create()  # create new delta_requst from this delta_stream
#      @delta_request.store_response_timing(file_name)  # 
      @delta_request.create_pretty_response_file(file_name)
    end
  end

  def self.update_database
    @delta_stream = DeltaStream.find_by_id(1)   # use the DeltaStream with id = 1
    @delta_stream = DeltaStream.create(id: 1, frequency_minutes: 3, delta_reachback: 6) if @delta_stream.nil?
    @delta_stream.fill_database
  end

end
