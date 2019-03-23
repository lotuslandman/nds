class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams, dependent: :destroy
  
  def set_parseable_bool(status)
    self.parseable = status
    self.save
  end

  def parse_and_store_time_info(response_time_info_line)
    rts = response_time_info_line.split(',')
    start_time = rts[0].strip
    end_time = rts[1].strip
    duration = rts[2].strip.to_f
    self.start_time = start_time
    self.end_time = end_time
    self.duration = duration
    self.save
  end

  def parse_response_and_store_pretty(response, file_path_pretty)
    begin
      pretty_response = Nokogiri::XML(response) { |config| config.strict }
    rescue
      puts "Nokogiri couldn't parse"
    end
    
    begin
      File.open(file_path_pretty, 'w') { |rf| rf.puts pretty_response}
    rescue
      puts "Couldn't write pretty"
      puts "file_path_pretty #{file_path_pretty}"
    end
    doc = pretty_response.remove_namespaces!       # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")   # prepare to store to Notam object
    @notam_array = notam_docs.collect do |notam_doc|
      @notam = self.notams.create()                # notams are created even if they are a repeat from the prior delta request.
      @notam.fill(notam_doc)                       # fills the database fields with things extracted from the Nokogiri document
    end
  end

  def create_dir(dir)
    Dir.mkdir(dir) unless File.exists?(dir)
  end

  def parse_response_time_save_pretty_store_in_db(file_name) # parse_response_time_save_pretty_store_in_db
    path = "/home/scott/dev/nds/ndsapp1/llog.txt"
    fn_frag = file_name.sub(" UTC","").split(' ').join('T')

    path_to_delta_files = "/home/scott/dev/nds/stream_files/stream_#{self.delta_stream.id}_files/2019-3/files_delta" # full_response_file_dir
    file_path_response = path_to_delta_files + "/"        + 'delta_'+fn_frag+'.xml'
    file_path_time     = path_to_delta_files + "_time/"   + 'delta_'+fn_frag+'_time.xml'
    file_path_pretty   = path_to_delta_files + "_pretty/" + 'delta_'+fn_frag+'_pretty.xml'
    response                = File.read(file_path_response)
    response_time_info_line = File.read(file_path_time)
    begin
      self.set_parseable_bool(true)
      create_dir(path_to_delta_files + "_pretty/")
      parse_response_and_store_pretty(response, file_path_pretty)
    rescue
      @delta_request.set_parseable_bool(false)
      puts "filename = #{file_name} - failure"
    end
    parse_and_store_time_info(response_time_info_line)
  end

  def scenario_notams(scenario)
    self.notams.select{|notam| notam.scenario == scenario}
  end
  
end
