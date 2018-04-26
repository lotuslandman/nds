class GraphController < ApplicationController

  def graph
    DeltaStream.update_database
    st = params[:start_graph].to_i * -1
    en = params[:end_graph].to_i * -1
    scenario  = params[:scenario]
    x = Notam.delta_request_chart(st, en, scenario)
  end

  def scenario
    DeltaStream.update_database
    st = params[:start_graph].to_i * -1
    en = params[:end_graph].to_i * -1
    scenario  = params[:scenario]
    x = Notam.delta_request_chart(st, en, scenario)
  end
end
