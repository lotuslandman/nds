class GraphController < ApplicationController

  def stream_to_environment_map
    case session[:env]
    when "fntb"
      1
    when "prod"
      2
    when "fntb_test"
      3
    else
      exit
    end
  end

  def graph
    @ds = DeltaStream.find_by_id(stream_to_environment_map)
    DeltaStream.update_database_for_all_streams
#    st = params[:start_graph].to_i * -1
#    en = params[:end_graph].to_i * -1

#    st = params[:start_graph]
#    st ||= session[:start_date]
#    @st = st.to_i * -1

    @st = params[:start_graph] ||= session[:start_date]
    session[:start_date] = @st
    @st = @st.to_i * -1

    @en = params[:end_graph] ||= session[:end_date]
    session[:end_date] = @en
    @en = @en.to_i * -1
    
    scenario  = params[:scenario]
#    x = ds.delta_request_chart(st, en, scenario)
  end

  def scenario
    @ds = DeltaStream.find_by_id(stream_to_environment_map)
    DeltaStream.update_database_for_all_streams
    st = params[:start_graph].to_i * -1
    en = params[:end_graph].to_i * -1
    scenario  = params[:scenario]
#    x = ds.delta_request_chart(st, en, scenario)
  end

  def prod
    session[:env] = "prod"
    redirect_to :action => "graph"
   end

  def fntb
    session[:env] = "fntb"
    redirect_to :action => "graph"
   end

  def fntb_test
    session[:env] = "fntb_test"
    redirect_to :action => "graph"
   end
end
