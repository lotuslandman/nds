class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams, dependent: :destroy

#  class << self  # not the best way I'm sure - my version of global variables
#        attr_accessor :start_graph, :end_graph, :scenario
#    end
#
#  @start_graph = 10

  def parse_and_store_time_info
    rts = @response_time_info_line.split(',')
    start_time = rts[0].strip
    end_time = rts[1].strip
    duration = rts[2].strip.to_f
    self.start_time = start_time
    self.end_time = end_time
    self.duration = duration
    self.save
  end
  
  def create_pretty_response_file(file_name)
    path = "/home/scott/dev/nds/ndsapp1/llog.txt"
#    self.request_time = file_name
    #    self.save
    binding.pry
    fn_frag = file_name.sub(" UTC","").split(' ').join('T')
    fn_f = 'delta_'+fn_frag+'.xml'
    fn_t = 'delta_'+fn_frag+'_time.xml'
    stream_number = self.delta_stream.id
    full_response_file_dir = "/home/scott/dev/nds/stream_files/stream_#{stream_number.to_s}_files/2019-3/files_delta"
    @response                = File.read(full_response_file_dir+"/"+fn_f)
    @response_time_info_line = File.read(full_response_file_dir+"_time/"+fn_t)
    parse_and_store_time_info
    doc_w_name_space = pretty_response = Nokogiri::XML(@response) { |config| config.strict }
    doc = doc_w_name_space.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")
    @notam_array = notam_docs.collect do |notam|
      Notam.new(notam)
    end
    
#    @notam_array = notam_docs.collect do |notam_doc|  # uncomment 4 lines so scenario and other NOTAM specific fns work
#      @notam = self.notams.create()             # notams are created even if they are a repeat from the prior delta request.
#      @notam.fill(notam_doc)                    # fills the database fields with things extracted from the Nokogiri document
#    end
  end

  def scenario_notams(scenario)
    self.notams.select{|notam| notam.scenario == scenario}
  end
  
end
