class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  def get_filenames
    Dir.glob("/home/scott/development/nds/files_delta/*").sort.collect do |fnp|
        '../files_delta/'+File.basename(fnp)  # have to back out of rails directory with ../
      end
  end
  
  def fill_database
    file_name_array = get_filenames                                       
    request_type  = :delta
    file_name_array.sort.each do |file_name|
        @delta_request = self.delta_requests.create()
        @delta_request.create_pretty_response_file(file_name)
      end
  end
  
end
