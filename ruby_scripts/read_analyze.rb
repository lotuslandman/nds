# This is the second stage, where the stored raw AIXM files are parsed and analyzed

require 'rubygems'
require 'pry'
gem 'nokogiri' 
require 'nokogiri' 
require 'fileutils'
require 'pony'

class Notam
  attr_reader :notam_doc, :trans_id, :scenario, :xsi_nil_present, :begin_position, :end_position, :time_position

  def initialize(notam_doc)
    @notam_doc = notam_doc   # this will be a Nokogiri node (or a Nokogiri document with pointer to node) need to search relative from here
    @trans_id = self.notam_doc.attr('id')
    @scenario = self.notam_doc.xpath(".//scenario/text()")
    @begin_position = self.notam_doc.xpath(".//beginPosition/text()")
    @end_position = self.notam_doc.xpath(".//endPosition/text()")
    @time_position = self.notam_doc.xpath(".//timePosition/text()")
    xsi_nil_list = self.notam_doc.xpath(".//*[@nil='true'][text()]")
    @xsi_nil_present = xsi_nil_list.size > 0
    #    @fns_id_array = notams.collect { |notam| notam.attr('id') }
  end
end

class RequestResponse   # Will create the appropriate request.xml file for the curl command and capture the output in response.xml
  attr_reader :request_type, :response, :delta_file_name, :notam_array, :fns_id_array, :scenario_id_array 

  def initialize(params = {})    #endpoint, username, password, request_type
    @request_type = params.fetch(:request_type, '')    # only one to have a default
  end

  def create_pretty_response_file(file_name)
    @response = File.read(file_name)
    pretty_response = Nokogiri::XML(@response) { |config| config.strict }
    doc = pretty_response.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")
    @notam_array = notam_docs.collect do |notam|
      Notam.new(notam)
    end
  end
 
  def inspect_notams
    puts "notam_array.size #{notam_array.size}"
    notam_array.collect do |nd|
      puts "transaction ID: #{nd.trans_id}, scenario: #{nd.scenario}, xsi_nil_issue?: #{nd.xsi_nil_present}, endPoistion: #{nd.begin_position}"
    end      
  end

end

file_name_array = Dir.glob("/home/scott/development/nds/files_delta/*").collect do |fnp|
  'files_delta/'+File.basename(fnp)
end
request_type  = :delta
file_name_array.sort.each do |file_name|
  puts file_name
  req = RequestResponse.new(:request_type => request_type)
  req.create_pretty_response_file(file_name)
  req.inspect_notams
end

