class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams, dependent: :destroy

  class << self  # not the best way I'm sure - my version of global variables
        attr_accessor :start_graph, :end_graph, :scenario
    end

  @start_graph = 10
  
  def create_pretty_response_file(file_name)   #### !!!!!!! WARNING Hardcoded stream 3  #######
    self.request_time = file_name
    self.save
    fn = 'delta_'+file_name.sub(" UTC","").split(' ').join('T')+'.xml'
    @response = File.read('/home/scott/dev/nds/stream_files/stream_3_files/2019-3/files_delta/'+fn)
    doc_w_name_space = pretty_response = Nokogiri::XML(@response) { |config| config.strict }
    doc = doc_w_name_space.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")
    @notam_array = notam_docs.collect do |notam_doc|
      @notam = self.notams.create()             # notams are created even if they are a repeat from the prior delta request.
      @notam.fill(notam_doc)
    end
  end

  def scenario_notams(scenario)
    self.notams.select{|notam| notam.scenario == scenario}
  end
  
end

#  def inspect_notams
#    @notam_array.collect do |nd|
#      puts "transaction ID: #{nd.trans_id}, scenario: #{nd.scenario}, xsi_nil_issue?: #{nd.xsi_nil_present}, endPoistion: #{nd.begin_position}"
#    end      
#  end
#end
