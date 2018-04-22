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
  
  def self.notams_grouped_by_request_date
    a = []
    # builds array of hashes where index is to be grouped
    DeltaRequest.all.collect { |dr| a << {dr.request_time => dr.notams.size}}
    aa = a[45..47]
    # takes array of hashes and makes hash
    aaa = aa.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    [{'Apples'=>3, 'Oranges'=>2, 'Strawberries'=>1},
     {'Red'=>40, 'Brown'=>32, 'Blue'=>21}]
    [
      {
        name: "Fantasy & Sci Fi", 
        data: [["2010", 10], ["2020", 16], ["2030", 28]]
      },
      {
        name: "Romance", 
        data: [["2010", 24], ["2020", 22], ["2030", 19]]
      },
      {
        name: "Mystery/Crime", 
        data: [["2010", 20], ["2020", 23], ["2030", 29]]
      }
    ]
  end
end
