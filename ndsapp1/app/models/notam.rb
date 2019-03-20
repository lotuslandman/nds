class Notam < ApplicationRecord
  belongs_to :delta_request

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
  
end
