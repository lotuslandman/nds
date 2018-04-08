# rr_notam
# Will call request response bulk, delta, and by transaction ID

require 'rubygems'
gem 'nokogiri' 
require 'nokogiri' 
require 'fileutils'
require 'pony'

Pony.options = {
  :subject => "Some Subject",
  :body => "This is the body.",
  :via => :smtp,
  :to => ['scott.weaver@jma-solutions.com', 'scott12@fastmail.fm'],
  :from => 'scott.weaver@jma-solutions.com',
  :via_options => {
    :address              => 'mail.messagingengine.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => 'sweaver@fastmail.fm',
    :password             => 'BvIYPuS7BB',
    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
    :domain               => "localhost.localdomain"
  }
}

class Notam
  attr_reader :trans_id

  def initalize(axim)
  end
end

class Request   # Will create the appropriate request.xml file for the curl command and capture the output in response.xml
  attr_reader :username, :password, :trans_id, :request_type, :delta_date, :request_xml

  def initialize(username, password, request_type, trans_id, delta_date)
    @username = username
    @password = password
    @request_type = request_type
    @trans_id = trans_id
    @delta_date = delta_date
    
    xml_request_template = '
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wfs="http://www.opengis.net/wfs/2.0" xmlns:fes="http://www.opengis.net/fes/2.0">
   <soapenv:Header xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:Security>
         <wsse:UsernameToken>
             <wsse:Username>USERNAME</wsse:Username>
            <wsse:Password>Password123!</wsse:Password>
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

    case request_type
    when :bulk
      "do this"
    when :delta
      "do that"
    when :transaction_id
      x = xml_request_template.sub "REQUEST",  "<fes:ResourceId rid=\"#{trans_id.to_s}\"/>"
      y = x.sub "USERNAME",  @username
      @request_xml = y.sub "PASSWORD", @password
    else
      puts "Request must be of type :bulk, :delta, or :transaction_id"
    end
  end
end

transaction_id_array = [47780365,47780366,47780367]


puts 'top'
transaction_id_array.collect do |ti|
  req = Request.new("UAT_NDS_USER_01", "Password123!", :transaction_id, ti, "")
  File.open("request.xml", 'w') { |rf| rf.puts req.request_xml }  # make the file xml_request
  curl_command_for_trans_id = 'curl --silent --insecure -H "Content-Type: text/xml; charset=utf-8" -H "SOAPAction:"  -d @request.xml -X POST  https://xxx.xx.xx.xx/notamWFS/services/NOTAMDistributionService > transaction_id_files/'+req.trans_id.to_s+'.xml'
  system(curl_command_for_trans_id)                               # have ruby run the req/resp service 
  xmllint_command_for_trans_id = 'xmllint --format transaction_id_files/'+req.trans_id.to_s+'.xml > transaction_id_files/'+req.trans_id.to_s+'_formatted.xml'
  system(xmllint_command_for_trans_id)                               # have ruby run the req/resp service 
end
exit

class ValidationError
    
  attr_reader :xmlfilename, :scenario, :href_array_string, :good_hrefs, :valid_hrefs, :an_offender
  
  def initialize(xmlfilename)
    # Instance variables  
    @xmlfilename = xmlfilename
    read_lines = IO.readlines(xmlfilename)
    xml_file_string = read_lines.join('')

    @scenario = 'none'
    scenario_split = xml_file_string.split("<event:scenario>")
    yy = scenario_split[1] unless scenario_split.nil?
    @scenario = yy[0..10].split("<")[0] unless yy.nil?

    href_split = xml_file_string.split("href=\"")[1..-1]
    href_split.shift # only interested in what is after the first href (remove all before it)
    href_array = []
    href_split.map do |st|
      href_array << st.split("\"")[0]
    end
    @good_hrefs = true
    href_array.map do |hr|
      @good_hrefs = false if hr[0] != '#'
    end
    @href_array_string = href_array.join(", ")

    @valid_hrefs = true
    @an_offender = false
    href_array.map do |hr|
      hr_temp = hr
      hr_temp = hr[1..-1] if hr[0] == "#"  #hr_temp is hr, shaved of # if necessary
      if not hr_temp.nil? and not xml_file_string.include?(['"',hr_temp,'"'].join)
        @valid_hrefs = false
        @an_offender = hr_temp
      end
    end
  end
end  

def load_a_notam(ti)
  xml_request_1 = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wfs="http://www.opengis.net/wfs/2.0" xmlns:fes="http://www.opengis.net/fes/2.0">
   <soapenv:Header xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:Security>
         <wsse:UsernameToken>
             <wsse:Username>UAT_NDS_USER_01</wsse:Username>
            <wsse:Password>Password123!</wsse:Password>
         </wsse:UsernameToken>
      </wsse:Security>
   </soapenv:Header>
   <soapenv:Body>
      <wfs:GetFeature service="WFS" version="2.0.0" resultType="results" outputFormat="application/aixm+xml; version=5.1">
         <wfs:Query typeNames="">
            <fes:Filter>
               <fes:ResourceId rid="'
  xml_request_2 = '"/>
            </fes:Filter>
         </wfs:Query>
      </wfs:GetFeature>
   </soapenv:Body>
</soapenv:Envelope>'
  xml_request = xml_request_1 + ti.to_s + xml_request_2
  File.open("request_xml.xml", 'w') { |rf| rf.puts xml_request }  # make the file xml_request
  curl_command_for_trans_id = 'curl --silent --insecure -H "Content-Type: text/xml; charset=utf-8" -H "SOAPAction:"  -d @request_xml.xml -X POST  https://155.178.63.81/notamWFS/services/NOTAMDistributionService > transaction_id_files/'+ti.to_s+'.xml'
  system(curl_command_for_trans_id)                               # have ruby run the req/resp service 
end

def load_all_notams(transaction_array)  
  transaction_array.collect do |trans_id|
    load_a_notam(trans_id)
  end
end

def parse_valid_file(doc, trans_id, i)
  doc.remove_namespaces!   # seems to be necessary for Nokogiri - simplifies XPATH statements too
  xsi_list = doc.xpath("//*[@nil='true'][text()]")
  scenario_number = doc.at_xpath("*//scenario/text()")
  xsi_list_cleaned = xsi_list.collect do |xsi|
    xsi.to_s.split(' ')[0].split('<')[1]
  end.join(',')
  issue_present = (xsi_list.size != 0)
  puts ["#{Time.now.to_s}   Loop number: #{i} ",trans_id.to_s,scenario_number,xsi_list.size.to_s,xsi_list_cleaned].join(',') if issue_present
  issue_present
end

def get_bad_xsi(xml_file)
  nil_splitter = 'xsi:nil="true">'                  # if this is an end tag
  xsi_array = xml_file.split(nil_splitter)
  if (xsi_array.size > 1)
   xsi_array.collect do |xsi_piece|
#      puts xsi_piece.split('>')[-1] + nil_splitter
    end
  end
  xsi_array.size
end

def get_scenario(xml_file)
  scenario_splitter = 'scenario'  
  xml_file.split(scenario_splitter)[1].split('>')[1].split('<')[0]
end

def parse_invalid_file(xml_file_name, xml_file, trans_id,e)
#  puts "Caught exception: #{xml_file_name} #{e}"
  xsi_array_size = get_bad_xsi(xml_file)
  scenario = get_scenario(xml_file)
  puts "Invalid XML:  Transactionid: " + trans_id.to_s + "   Scenario: " + scenario + "    Number of xsi issues: " + xsi_array_size.to_s
end

def analyze(transaction_array,i)
  issue_present_for_batch = false
  sample_bad_doc = "Initial bad doc (not a true error)"
  transaction_array.collect do |trans_id|
    xml_file_name = "transaction_id_files/#{trans_id}.xml"
    xml_file = File.read(xml_file_name)
    begin
      doc     = Nokogiri::XML(xml_file) { |config| config.strict }
      issue_present = parse_valid_file(doc, trans_id,i)
      if issue_present
        issue_present_for_batch = issue_present
        sample_bad_doc = doc
      end
    rescue Nokogiri::XML::SyntaxError => e
      puts "bad file #{trans_id}"
#      parse_invalid_file(xml_file_name, xml_file,trans_id,e)
    end
  end
  return [issue_present_for_batch, sample_bad_doc]
end

transaction_id_array = [47780365,47780366,47780367,47780368,47780369,47780370,47780371,47780372,47780373,47780374,47780375,47780376,47780377,47780378,47780379,47780380,47780381,47780382,47780383,47780384,47780385,47780386,47780387,47780388,
                        47780389,47780390,47780391,47780392,47780393,47780394,47780395,47780396,47780397,47780398,47780399,47780400,47780401,47780402,47780403,47780404,47780405,47780406,47780407,47780408,47780409,47780410,47780411,47780412,
                        47780413,47780414]

transaction_id_array = [47780365,47780366,47780367]

transaction_id_array_w_one = transaction_id_array + [1]

num = 200000
i = 0
old_issue_present = false
issue_present_for_batch = false
while i < num  do
  puts i
  load_all_notams(transaction_id_array)
  issue_present_for_batch, sample_bad_doc = analyze(transaction_id_array_w_one,i)
  puts "Email Sent: Issue Present for Batch? #{issue_present_for_batch}" if i==0
  Pony.mail(:subject => "#{Time.now.to_s} Program starts", :body => "First batch: #{issue_present_for_batch.to_s}") if i==0
  
  if (old_issue_present != issue_present_for_batch)
    if issue_present_for_batch
      puts "Email Sent: Issue Present For Batch"
      Pony.mail(:subject => "#{Time.now.to_s} Issue Present", :body => "#{sample_bad_doc}")
    else
      puts "Email Sent: Issue Not Present For Batch"
      Pony.mail(:subject => "#{Time.now.to_s} Issue not Present", :body => "#{sample_bad_doc}")
    end
  end
  
  old_issue_present = issue_present_for_batch
  i +=1
  sleep(60)
end

