class Notam < ApplicationRecord
  belongs_to :delta_request

#  def initialize(parms)
#    @notam_doc = parms[:notam_doc]  # this will be a Nokogiri node (or a Nokogiri document with pointer to node) need to search relative from here
#  end

  def fill(notam_doc)
    self.transaction_id = notam_doc.attr('id')[-8..-1]
    self.scenario = notam_doc.xpath(".//scenario/text()")
    self.end_position = notam_doc.xpath(".//endPosition/text()")
    xsi_nil_list = notam_doc.xpath(".//*[@nil='true'][text()]")
    self.xsi_nil_error = xsi_nil_list.size > 0
    self.save
  end

  def request_date
    self.delta_request.request_time.to_s
  end
  
  def self.delta_request_chart(st, en, scenario)

    notams_all = []
    notams_flt = []
    # builds array of hashes where index is to be grouped
    DeltaRequest.all.collect { |dr| notams_all << {dr.request_time => dr.notams.size}}
    DeltaRequest.all.collect { |dr| notams_flt << {dr.request_time => (dr.scenario_notams(scenario).size)}}
    #    notams_all_1 = notams_all[50..60]
    #    notams_flt_1 = notams_flt[50..60]
    notams_all_1 = notams_all[st..en]
    notams_flt_1 = notams_flt[st..en]
    # takes array of hashes and makes hash, flattening allong hash keys
    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    all_notams_w_filtered = [
      {name: "All Notams", data: notams_all_2},
      {name: "Filtered Notams", data: notams_flt_2}
    ]
  end
end
