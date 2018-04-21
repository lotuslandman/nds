class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams, dependent: :destroy

#  attr_reader :request_type, :response, :delta_file_name, :notam_array, :fns_id_array, :scenario_id_array 
  
#  def initialize(params = {})    #endpoint, username, password, request_type
#    @request_type = params.fetch(:request_type, '')    # only one to have a default
#  end
#  
  def create_pretty_response_file(file_name)
    self.request_time = file_name.split("delta")[2].split('.')[0][1..-1]
    self.save
    @response = File.read(file_name)
    doc_w_name_space = pretty_response = Nokogiri::XML(@response) { |config| config.strict }
    doc = doc_w_name_space.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")
    @notam_array = notam_docs.collect do |notam_doc|
      @notam = self.notams.create()
      @notam.fill(notam_doc)
    end

  end
end

#  def inspect_notams
#    @notam_array.collect do |nd|
#      puts "transaction ID: #{nd.trans_id}, scenario: #{nd.scenario}, xsi_nil_issue?: #{nd.xsi_nil_present}, endPoistion: #{nd.begin_position}"
#    end      
#  end
#end
