require 'time'

class GraphController < ApplicationController

  def environment_to_stream_map
    case session[:env]
    when "fntb"
      1   # these are the stream ids
    when "prod"
      2
    when "fntb_test"
      3
    else
      exit
    end
  end


  def graph
#    update_database_for_all_streams
    @ds = DeltaStream.find_by_id(environment_to_stream_map)

    start_date_string = params[:start_graph] 
    start_date_string ||= session[:start_date]  # assumes session is string
    @start_date_string = start_date_string

    end_date_string = params[:end_graph] 
    end_date_string ||= session[:end_date]  # assumes session is string
    @end_date_string = end_date_string
    
    session[:start_date] = start_date_string
    session[:end_date] = end_date_string
    
    @scenario  = params[:scenario]  # if no scenario entered no need to store
    @y_axis = session[:y_axis]
    @get_column_chart_data = @ds.column_chart_data(@start_date_string, @end_date_string, @scenario, @y_axis) 
  end

#  def scenario
#    @ds = DeltaStream.find_by_id(stream_to_environment_map)
#    DeltaStream.update_database_for_all_streams
#    st = params[:start_graph].to_i * -1
#    en = params[:end_graph].to_i * -1
#    scenario  = params[:scenario]
#  end

  def response_time
    session[:y_axis] = "response_time"
    redirect_to :action => "graph"
  end
  
  def number_of_notams
    session[:y_axis] = "number_of_notams"
    redirect_to :action => "graph"
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
