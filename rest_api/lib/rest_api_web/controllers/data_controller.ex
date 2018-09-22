defmodule RestApiWeb.DataController do
  use RestApiWeb, :controller
  require Logger

  def index(conn, _params) do
    my_data = %{val1: %{"one" => "this is the first value", "two" => "this is the second value"},
                val2: [1,2,3,4,5,6]}
    json conn, my_data
  end

  def post(conn, _params) do
    Logger.debug("Json received=#{inspect conn.body_params}")

    # get the request from the connection data
    %{"machine" => machine, "date" => date, "type" => type} = conn.body_params

    # convert the date into the correct form
    [month, day, year] = String.split(date, "/")
    {:ok, date_struct} = Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

    # get the requested data from the appropriate store
    state = DataPointsStore.start(machine, date_struct)
    ret_data = DataPointsStore.get(type, state)

    # convert the data from the store to two arrays, one for time and one for the values
    x_data = Map.keys(ret_data)
    y_data = Map.values(ret_data)

    connection_id = "stringdata1234"
    is_raw = true

    # package the data up to return to the gui
    result = %{
      "ConnectionId" => connection_id,
      "Xdata" => x_data,
      "Ydata" => y_data,
      "IsRaw" => is_raw,
      "VmName" => machine,
      "Date" => date,
      "MetricName" => type
    }
    
    json conn, result
  end

      # public string ConnectionId { get; private set; }
      # public long[] Xdata { get; private set; }
      # public float[] Ydata { get; private set; }
      # public bool IsRaw { get; private set; }
      # public string VmName { get; private set; }
      # public string Date { get; private set; }
      # public string MetricName { get; private set; }
end
