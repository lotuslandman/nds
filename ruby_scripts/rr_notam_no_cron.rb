# Will call request response bulk, delta, and by transaction ID

require 'rubygems'
require 'nokogiri'
require 'fileutils'

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
  attr_reader :endpoint, :username, :password, :request_type, :trans_id, :delta_date, :request_xml, :response, :pretty_response, :delta_file_name, :delta_file_name_pretty, :fns_id_array, :scenario_ids, :notam_array, :curl_start_time, :curl_end_time, :curl_duration

  def initialize(params = {})    #endpoint, username, password, request_type
    @username     = params.fetch(:username, '')
    @password     = params.fetch(:password, '')
    @endpoint     = params.fetch(:endpoint, '')
    @request_type = params.fetch(:request_type, '')    # only one to have a default
    @trans_id     = params.fetch(:trans_id, '')        # this should be in NOTAM only and not here
    @delta_date   = params.fetch(:delta_date, '')
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

  def create_request_xml_file(path)
    xrt1 = xml_request_template.sub "USERNAME",  @username
    xrt2 = xrt1.sub "PASSWORD", @password

    case self.request_type
    when :by_trans_id
      @request_xml = xrt2.sub "REQUEST",  "<fes:ResourceId rid=\"#{trans_id.to_s}\"/>"
    when :delta
      @request_xml = xrt2.sub "REQUEST",  "<fes:Function name=\"SearchByLastUpdateDate\"><fes:Literal>#{delta_date.to_s}</fes:Literal></fes:Function>"
    when :bulk
    else
      puts "Request must be of type :bulk, :delta, or :transaction_id"
    end
    File.open(path, 'w') { |rf| rf.puts request_xml}  # make the file xml_request
    ''
  end

  def create_response_file(path)
    @delta_file_name        = "files_delta/delta_#{self.delta_date}.xml"
    @delta_file_name_pretty = "files_delta_pretty/delta_#{self.delta_date}_pretty.xml"
    curl_command_1 = 'curl --silent --insecure -H "Content-Type: text/xml; charset=utf-8" -H "SOAPAction:"  -d @'+path+' -X POST END_POINT > '+@delta_file_name
    curl_command = curl_command_1.sub("END_POINT",self.endpoint)
    @curl_start_time = Time.now
    system(curl_command)
    @curl_end_time = Time.now
    @curl_duration = @curl_end_time - @curl_start_time
  end

  def create_pretty_response_file
    @response = File.read(self.delta_file_name)
    begin
      pretty_response = Nokogiri::XML(@response) { |config| config.strict }  # this creates an object that enables easy extraction of components from xml file
      @pretty_response = pretty_response
      File.open(@delta_file_name_pretty+"_pretty.xml", 'w') { |rf| rf.puts pretty_response}
      doc = pretty_response.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
      notam_docs = doc.xpath("//AIXMBasicMessage")  # breaks xml into a set of NOTAMs
      @notam_array = notam_docs.collect do |notam|
        Notam.new(notam)
      end
    rescue
      puts "Error: response could not be parsed, maybe service interruption?"
      nil
    end
  end

end

def find_date_at_start_of_delta
#  minutes_ago = ARGV[0].to_i
  minutes_ago = 6
  time_range = minutes_ago * 60 # convert minutes to seconds
  t = Time.now - time_range
  t.strftime "%Y-%m-%dT%H:%M:%S"
end

def do_request(delta_date)
  transaction_id = "" # must be empty string if doing delta ?
  request_type = :delta                   # This is set up as a delta pull

#  username = "UAT_NDS_USER_01"
#  password = "Password123!"
#  endpoint = "https://155.178.63.75/notamWFS/services/NOTAMDistributionService"

  # Directly below is currently set up to request from a direct connection not going through SWIM
  # endpoint will need to be replaced with a SWIM version of this.

  username = "aclskang@outlook.com"
  password = "FNStest123$"
  endpoint = "https://notams.aim.faa.gov/notamWFS/services/NOTAMDistributionService" #?wsdl


  req = RequestResponse.new(:endpoint => endpoint, :username => username, :password => password, :request_type => request_type, :trans_id => transaction_id, :delta_date => delta_date)
  path = "/home/nds/dev/nds/request.xml"
  req.create_request_xml_file(path)  # creates the file pointed to by the curl command that makes the delta request
  req.create_response_file(path)     # finds the request file, calls the curl command making the delta request
  req.create_pretty_response_file    # captures the file so the Nokogiri library can extract message parts
  req
end

def execute_delta_pull(loop_count, log_file)
  start_time = Time.now
  delta_date = find_date_at_start_of_delta
  req = do_request(delta_date)
  #  sleep((rand() * 180).to_i + 60)   # used this to puff up duration times to test what would happen if duration took longer than 3 minutes
  end_time= Time.now
  duration = end_time - start_time
  if req.notam_array.nil?
    log_file.puts "#{loop_count}, bad output, #{start_time}, #{end_time}, #{duration}"   # this will end up in the file in the log directory
  else
    log_file.puts "#{loop_count}, #{req.notam_array.size}, #{start_time}, #{end_time}, #{duration}"   # this will end up in the file in the log directory
  end
end

def next_3_min_start_time    # Find next 3-minute interval starting on the hour
  tn = Time.now + (3 * 60)
  tnm = tn.min
  next_min = tnm - (tnm%3)
  Time.utc(tn.year, tn.mon, tn.day, tn.hour, next_min, 0)  # future time point to start loop
end

def create_dir(dir)
  Dir.mkdir(dir) unless File.exists?(dir)
end

#if ARGV.size != 1
#  puts 'call with a single integer argument that specifies how many minutes to reach back in delta request'
#  exit
#end

com = "rm -r files_delta"
system(com)
com = "rm -r files_delta_pretty"
system(com)
com = "rm -r log"
system(com)

create_dir("files_delta_pretty")
create_dir(dir = "files_delta")
create_dir(dir = "log")

loop_count = 1
max_loop_count = 20 * 24 # runs for 24 hours
t = Time.now
next_start_point = next_3_min_start_time # future time point to start loop
zip_file_name = "#{t.asctime}.tar.gz".gsub(/\s+/, "").gsub(":", "-")
log_file_name = "log/#{t.to_s}.log"

File.open(log_file_name, 'w') do |log_file|
  log_file.puts("delta count, no of NOTAMs, start, end, duration")
end
while loop_count < max_loop_count
  puts "loop_count = #{loop_count}"
  sleep_amount = next_start_point - Time.now
  sleep(sleep_amount)                    # wait until next 3-minute start point
  File.open(log_file_name, 'a') do |log_file|
    execute_delta_pull(loop_count, log_file)
  end
  loop_count += 1
  last_start_point = next_start_point
  next_start_point = next_3_min_start_time # future time point to start loop
  time_between_starts = next_start_point - last_start_point
  puts "Warning time between starts is greater than 3 minutes" if time_between_starts > 181  # this will also be extracted from the log file with the two start times seperated by more than 3 minutes (6 or 9 minutes for example)
end

command = "tar czvf #{zip_file_name} files_delta files_delta_pretty log"
puts command
system(command)
