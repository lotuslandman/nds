class GraphController < ApplicationController

  def search
  end

  def graph
    DeltaStream.update_database
    st = params[:start_graph].to_i * -1
    en = params[:end_graph].to_i * -1
    scenario  = params[:scenario]
    x = Notam.delta_request_chart(st, en, scenario)
#    redirect_to :controller => 'graph', :action => 'graph', :format => 'html'
  end
end
