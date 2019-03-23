# Stream: 1
# Environment: fntb
# Request Type: delta
# Reach back: 6 minutes
# Frequency: 3 minutes (see crontab for this stream)

stream              =  1
env                 =  "fntb"
request_type        = :delta
delta_pull_duration =  6 # ARGV[0].to_i # 6 minutes ago

require 'rubygems'
require 'pry'
gem 'nokogiri' 
require 'nokogiri' 
require 'fileutils'
require 'pony'
require 'time'

#class Notam
#  attr_reader :notam_doc, :trans_id, :scenario, :xsi_nil_present, :begin_position, :end_position, :time_position
#
#  def initialize(notam_doc)
#    @notam_doc = notam_doc   # this will be a Nokogiri node (or a Nokogiri document with pointer to node) need to search relative from here
#    @trans_id = self.notam_doc.attr('id')
#    @scenario = self.notam_doc.xpath(".//scenario/text()")
#    @begin_position = self.notam_doc.xpath(".//beginPosition/text()")
#    @end_position = self.notam_doc.xpath(".//endPosition/text()")
#    @time_position = self.notam_doc.xpath(".//timePosition/text()")
#    xsi_nil_list = self.notam_doc.xpath(".//*[@nil='true'][text()]")
#    @xsi_nil_present = xsi_nil_list.size > 0
#    #    @fns_id_array = notams.collect { |notam| notam.attr('id') }
#  end
#end

class RequestResponse   # Will create the appropriate request.xml file for the curl command and capture the output in response.xml
  attr_reader :endpoint, :username, :password, :request_type, :trans_id, :delta_start_date, :delta_end_date, :request_xml, :response, :pretty_response, :delta_file_name, :delta_file_name_pretty, :delta_file_name_time, :fns_id_array, :scenario_ids, :notam_array

  def initialize(params = {})    #endpoint, username, password, request_type
    @username     = params.fetch(:username, '')
    @password     = params.fetch(:password, '')
    @endpoint     = params.fetch(:endpoint, '')
    @request_type = params.fetch(:request_type, '')    # only one to have a default
    @trans_id     = params.fetch(:trans_id, '')        # this should be in NOTAM only and not here
    @delta_start_date = params.fetch(:delta_start_date, '')
    @delta_end_date = params.fetch(:delta_end_date, '')
  end

  def xml_request_template
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wfs="http://www.opengis.net/wfs/2.0" xmlns:fes="http://www.opengis.net/fes/2.0">
   <soapenv:Header xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:Security>
         <wsse:UsernameToken>
             <wsse:Username>USERNAME</wsse:Username>
            <wsse:Password>PASSWORD</wsse:Password>
         </wsse:UsernameToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <wfs:GetFeature service="WFS" version="2.0.0" resultType="results" outputFormat="application/aixm+xml; version=5.1">
         <wfs:Query typeNames="">
            <fes:Filter>
               REQUEST
            </fes:Filter>
         </wfs:Query>
      </wfs:GetFeature>
   </soapenv:Body>
</soapenv:Envelope>'
  end
  
  def create_request_xml_file(request_path)
    xrt1 = xml_request_template.sub "USERNAME",  @username
    xrt2 = xrt1.sub "PASSWORD", @password

    case self.request_type    # The keyword "REQUEST" is replaced by request type-specific xml
    when :by_trans_id  # will implement this latter perhaps
      @request_xml = xrt2.sub "REQUEST",  "<fes:ResourceId rid=\"#{trans_id.to_s}\"/>"
    when :delta
      @request_xml = xrt2.sub "REQUEST",  "<fes:Function name=\"SearchByLastUpdateDate\"><fes:Literal>#{delta_start_date.to_s}</fes:Literal></fes:Function>"
    when :bulk         # will implement this latter perhaps
    else
      puts "Request must be of type :bulk, :delta, or :transaction_id"
      exit
    end
    File.open(request_path, 'w') { |rf| rf.puts request_xml}  # make the file xml_request
    ''
  end

  def create_response_file(request_path, env, stream)
    t = Time.now;

    stream_files_path = "stream_files/"    
    create_dir(stream_files_path)              # first level "stream_files/"

    stream_files_env_path = stream_files_path + "stream_#{stream}_files/"  
    create_dir(stream_files_env_path)          # second level "stream_files/fntb_stream_files/"

    t = Time.now
    month_string_path = "#{t.year}-#{t.month}/"
    stream_files_env_month_path = stream_files_env_path + month_string_path
    create_dir(stream_files_env_month_path)    # third level "stream_files/fntb_stream_files/2019-03/"

    stream_files_env_month_delta = stream_files_env_month_path + "files_delta/"
    stream_files_env_month_delta_pretty = stream_files_env_month_path + "files_delta_pretty/"
    stream_files_env_month_delta_time = stream_files_env_month_path + "files_delta_time/"
    create_dir(stream_files_env_month_delta)
    create_dir(stream_files_env_month_delta_pretty)
    create_dir(stream_files_env_month_delta_time)

    @delta_file_name        = stream_files_env_month_delta + "delta_#{self.delta_end_date}.xml"
    @delta_file_name_pretty = stream_files_env_month_delta_pretty + "delta_#{self.delta_end_date}_pretty.xml"
    @delta_file_name_time   = stream_files_env_month_delta_time + "delta_#{self.delta_end_date}_time.xml"
    curl_command_1 = 'curl --silent --insecure -H "Content-Type: text/xml; charset=utf-8" -H "SOAPAction:"  -d @'+request_path+' -X POST END_POINT > '+@delta_file_name
    curl_command = curl_command_1.sub("END_POINT",self.endpoint)
    start_delta_time = Time.now
    system(curl_command)
    end_delta_time = Time.now
    duration = end_delta_time - start_delta_time
    File.open(@delta_file_name_time, 'w') { |rf| rf.puts "#{start_delta_time}, #{end_delta_time}, #{duration}"}
    puts "#{start_delta_time},#{end_delta_time},#{duration}"
  end

#  def create_pretty_response_file
#    @response = File.read(self.delta_file_name)
#    pretty_response = Nokogiri::XML(@response) { |config| config.strict }
#    @pretty_response = pretty_response
#    File.open(@delta_file_name_pretty, 'w') { |rf| rf.puts pretty_response}
#    doc = pretty_response.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
#    notam_docs = doc.xpath("//AIXMBasicMessage")
#    @notam_array = notam_docs.collect do |notam|
#      Notam.new(notam)
#    end
#  end

  def inspect_notams
    puts "notam_array.size #{notam_array.size}"
    notam_array.collect do |nd|
      puts "transaction ID: #{nd.trans_id}, scenario: #{nd.scenario}, xsi_nil_issue?: #{nd.xsi_nil_present}, endPoistion: #{nd.begin_position}"
    end      
  end

end

def find_delta_start_date(delta_pull_duration)
  time_range = delta_pull_duration * 60  # make into seconds
  end_time = Time.now
  start_time = end_time - time_range
  st = start_time.strftime "%Y-%m-%dT%H:%M:%S"
  et = end_time.strftime "%Y-%m-%dT%H:%M:%S"
  [st, et]
end

request_path = "temporary/request#{stream}.xml"
system_information_hash = File.read("ignore/connection_information_#{env}.rb")
system_information = eval(system_information_hash)
username = system_information[:username]
password = system_information[:password]
endpoint = system_information[:endpoint]

transaction_id      = "" # for 2nd floor test
delta_start_date, delta_end_date = find_delta_start_date(delta_pull_duration)
req = RequestResponse.new(:endpoint => endpoint, :username => username, :password => password, :request_type => request_type, :trans_id => transaction_id, :delta_start_date => delta_start_date,  :delta_end_date => delta_end_date)
req.create_request_xml_file(request_path)
duration = req.create_response_file(request_path, env, stream)
# req.create_pretty_response_file
