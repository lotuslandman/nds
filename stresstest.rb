# Stream: 4
# Environment: fntb

stream              =  4      # (stream 4 is for stress testing in fntb)
env                 =  "fntb" # (stream 4 is for stress testing in fntb)

require 'rubygems'
require 'fileutils'
require 'time'

class RequestResponse   # Will create the appropriate request.xml file for the curl command and capture the output in response.xml
  attr_reader :endpoint, :username, :password, :request_type, :trans_id, :delta_start_date, :delta_end_date, :request_xml, :response, :pretty_response, :delta_file_name, :delta_file_name_pretty, :delta_file_name_time, :fns_id_array, :scenario_ids, :notam_array, :location

  def initialize(params = {})    #endpoint, username, password, request_type
    @username     = params.fetch(:username, '')
    @password     = params.fetch(:password, '')
    @endpoint     = params.fetch(:endpoint, '')
    @request_type = params.fetch(:request_type, '')    # only one to have a default
    @trans_id     = params.fetch(:trans_id, '')        # this should be in NOTAM only and not here
    @delta_start_date = params.fetch(:delta_start_date, '')
    @delta_end_date = params.fetch(:delta_end_date, '')
    @location       = params.fetch(:location, '')
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
    when :location  # to support stress testing on FNTB
      @request_xml = xrt2.sub "REQUEST",  "<fes:Function name=\"SearchByDesignator\"><fes:Literal>#{location}</fes:Literal></fes:Function>"
    when :bulk         # will implement this latter perhaps
    else
      puts "Request must be of type :bulk, :delta, :location, or :transaction_id"
      exit
    end
    File.open(request_path, 'w') { |rf| rf.puts request_xml}  # make the file xml_request
    ''
  end

  def create_dir(dir)
    Dir.mkdir(dir) unless File.exists?(dir)
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
    file_size = File.size(@delta_file_name).to_f / 2**20
    file_size_formatted = ('%.2f' % file_size)
    File.open(@delta_file_name_time, 'w') { |rf| rf.puts "#{start_delta_time}, #{end_delta_time}, #{duration} sec, #{file_size_formatted} MB"}
    puts "#{start_delta_time}, #{end_delta_time}, #{duration} sec, #{file_size_formatted} MB"
  end
end

def find_delta_start_date(delta_pull_duration_in_hours)
  time_range = delta_pull_duration_in_hours * 60 * 60  # make into seconds
  end_time = Time.now
  start_time = end_time - time_range
  st = start_time.strftime "%Y-%m-%dT%H:%M:%S"
  et = end_time.strftime "%Y-%m-%dT%H:%M:%S"
  [st, et]
end

def airport_identifier_array
  ["ABE",
   "ABI",
   "ABQ",
   "ACK",
   "ACT",
   "ACY",
   "ADS",
   "ADW",
   "AEG",
   "AFW",
   "AGC",
   "AGS",
   "AHN",
   "ALB",
   "ALN",
   "ALO",
   "AMA",
   "ANC",
   "ANE",
   "APA",
   "APC",
   "APF",
   "ARA",
   "ARB",
   "ARM",
   "ARR",
   "ASE",
   "ASG",
   "ASH",
   "ATL",
   "ATW",
   "AUS",
   "AVL",
   "AVP",
   "AZO",
   "BAF",
   "BCT",
   "BDL",
   "BDR",
   "BED",
   "BFI",
   "BFL",
   "BFM",
   "BGM",
   "BGR",
   "BHM",
   "BIF",
   "BIL",
   "BIS",
   "BJC",
   "BKL",
   "BNA",
   "BOI",
   "BOS",
   "BPT",
   "BRO",
   "BTL",
   "BTR",
   "BTV",
   "BUF",
   "BUR",
   "BVI",
   "BVY",
   "BWI",
   "BZN",
   "CAE",
   "CAK",
   "CCR",
   "CDW",
   "CEF",
   "CGF",
   "CHA",
   "CHD",
   "CHO",
   "CHS",
   "CIC",
   "CID",
   "CKB",
   "CLE",
   "CLL",
   "CLT",
   "CMH",
   "CMI",
   "CNO",
   "COS",
   "COS",
   "CPR",
   "CPS",
   "CRE",
   "CRG",
   "CRP",
   "CRQ",
   "CRW",
   "CSG",
   "CTW",
   "CVG",
   "CWF",
   "CXO",
   "CXY",
   "DAB",
   "DAL",
   "DAY",
   "DCA",
   "DEN",
   "DET",
   "DLH",
   "DPA",
   "DSM",
   "DTN",
   "DTO",
   "DTW",
   "DVT",
   "DWH",
   "DXR",
   "ELM",
   "ELP",
   "EMT",
   "ENA",
   "ENW",
   "ERI",
   "ETW",
   "EUG",
   "EVB",
   "EVV",
   "EWB",
   "EWR",
   "FAI",
   "FAR",
   "FAT",
   "FAY",
   "FCM",
   "FD1",
   "FFZ",
   "FLL",
   "FLO",
   "FMH",
   "FMN",
   "FMY",
   "FNT",
   "FOE",
   "FPR",
   "FRG",
   "FSD",
   "FSM",
   "FTG",
   "FTW",
   "FTY",
   "FUL",
   "FWA",
   "FWS",
   "FXE",
   "FYV",
   "GEG",
   "GGG",
   "GJT",
   "GKY",
   "GLS",
   "GMU",
   "GNV",
   "GON",
   "GPM",
   "GPT",
   "GRB",
   "GRR",
   "GSO",
   "GSP",
   "GTF",
   "GTU",
   "GYY",
   "HEF",
   "HFD",
   "HGR",
   "HHR",
   "HIO",
   "HKS",
   "HKY",
   "HND",
   "HOU",
   "HPN",
   "HRL",
   "HSV",
   "HTS",
   "HUF",
   "HUM",
   "HUT",
   "HVN",
   "HWD",
   "HWO",
   "HYA",
   "HYI",
   "IAD",
   "IAG",
   "IAH",
   "ICT",
   "ILG",
   "ILM",
   "IND",
   "INT",
   "ISM",
   "ISP",
   "IWA",
   "JAN",
   "JAX",
   "JFK",
   "JQF",
   "LAL",
   "LAN",
   "LAS",
   "LAX",
   "LBB",
   "LCH",
   "LCK",
   "LEX",
   "LFT",
   "LGA",
   "LGB",
   "LIT",
   "LNK",
   "LNS",
   "LOU",
   "LUK",
   "LVK",
   "LWM",
   "LYH",
   "LZU",
   "MAF",
   "MBS",
   "MCI",
   "MCN",
   "MCO",
   "MDT",
   "MDW",
   "MEI",
   "MEM",
   "MER",
   "MFD",
   "MFE",
   "MFR",
   "MGM",
   "MHR",
   "MHT",
   "MIA",
   "MIC",
   "MKC",
   "MKE",
   "MKG",
   "MLB",
   "MLI",
   "MLU",
   "MMU",
   "MOB",
   "MOD",
   "MQY",
   "MRI",
   "MRY",
   "MSN",
   "MSO",
   "MSO",
   "MSP",
   "MSY",
   "MTN",
   "MVY",
   "MWC",
   "MWH",
   "MYF",
   "MYR",
   "NEW",
   "NMM",
   "OAK",
   "OAK1",
   "OGD",
   "OJC",
   "OKC",
   "OLM",
   "OLV",
   "OMA",
   "OMN",
   "ONT",
   "OPF",
   "ORD",
   "ORF",
   "ORL",
   "ORN",
   "ORS",
   "OSH",
   "OSU",
   "OUN",
   "OWD",
   "OXC",
   "PAE",
   "PAO",
   "PBI",
   "PDK",
   "PDX",
   "PGD",
   "PHF",
   "PHL",
   "PHX",
   "PIA",
   "PIE",
   "PIT",
   "PMP",
   "PNE",
   "PNS",
   "POC",
   "POU",
   "PRC",
   "PSC",
   "PSP",
   "PTK",
   "PUB",
   "PVD",
   "PVU",
   "PWA",
   "PWK",
   "PWM",
   "R90",
   "RAL",
   "RBD",
   "RDG",
   "RDU",
   "RFD",
   "RHV",
   "RIC",
   "RME",
   "RNM",
   "RNO",
   "RNT",
   "ROA",
   "ROC",
   "ROW",
   "RST",
   "RSW",
   "RVS",
   "RYN",
   "RYY",
   "SAC",
   "SAN",
   "SAT",
   "SAV",
   "SBA",
   "SBN",
   "SBP",
   "SCH",
   "SCK",
   "SDF",
   "SDL",
   "SDM",
   "SEA",
   "SEE",
   "SFB",
   "SFF",
   "SFO",
   "SGF",
   "SGJ",
   "SGR",
   "SHV",
   "SJC",
   "SJT",
   "SLC",
   "SMF",
   "SMO",
   "SMX",
   "SNA",
   "SNS",
   "SPG",
   "SPI",
   "SQL",
   "SRQ",
   "SSF",
   "STL",
   "STP",
   "STS",
   "SUA",
   "SUS",
   "SUX",
   "SWF",
   "SYR",
   "TEB",
   "TIW",
   "TIX",
   "TKI",
   "TLH",
   "TMB",
   "TOA",
   "TOL",
   "TOP",
   "TPA",
   "TRI",
   "TTD",
   "TTN",
   "TUL",
   "TUS",
   "TXK",
   "TYR",
   "TYS",
   "U90",
   "UAO",
   "UES",
   "UGN",
   "VGT",
   "VNY",
   "VQQ",
   "VRB",
   "WHP",
   "WTW",
   "XNA",
   "YIP",
   "YKM",
   "YNG"
  ]
end

#### handles credentials ####
system_information_hash = File.read("ignore/connection_information_#{env}.rb")
system_information = eval(system_information_hash)
username = system_information[:username]  # HARDCODE for Stress Testing
password = system_information[:password]  # HARDCODE for Stress Testing
endpoint = system_information[:endpoint]  # HARDCODE for Stress Testing

  def create_dir(dir)
    Dir.mkdir(dir) unless File.exists?(dir)
  end

#### path/filename of request.xml ####
request_path = "temporary/request#{stream}.xml"
create_dir(request_path)

transaction_id      = "" # for 2nd floor test

first_arg = ARGV[0].to_s
case first_arg
when "location"
  puts "running #{ARGV[1]} location queries, each delayed by #{ARGV[2]} seconds"
  number_of_locations = ARGV[1].to_i
  location_delay = ARGV[2].to_i
  request_type = :location
  i = 0
  while i < number_of_locations 
    location = airport_identifier_array()[i]
    puts "Location: #{location}"
    req = RequestResponse.new(:endpoint => endpoint, :username => username, :password => password, :request_type => request_type, :trans_id => transaction_id, :location => location)
    req.create_request_xml_file(request_path)
    duration = req.create_response_file(request_path, env, stream)
    sleep(location_delay)
    i += 1
  end
when "delta"
  request_type = :delta
  delta_pull_duration_in_hours =  ARGV[1].to_i
  puts "running 1 delta query with a reachback of #{delta_pull_duration_in_hours} hour"
  delta_start_date, delta_end_date = find_delta_start_date(delta_pull_duration_in_hours)
  req = RequestResponse.new(:endpoint => endpoint, :username => username, :password => password, :request_type => request_type, :trans_id => transaction_id, :delta_start_date => delta_start_date,  :delta_end_date => delta_end_date)
  req.create_request_xml_file(request_path)
  duration = req.create_response_file(request_path, env, stream)
else
  puts "ruby stresstest.rb location number_of_airports sec_delay"
  puts "or"
  puts "ruby stresstest.rb delta delta_pull_reachback_in_hours"
  exit
end
