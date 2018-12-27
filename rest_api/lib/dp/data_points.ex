defmodule DataPoints do

  use GenServer
  require Logger

  @interval 10 * 1000
  @headers [:machine, :date, :time, :mem_max, :mem_avg, :mem_min, :cpu_max, :cpu_avg, :cpu_min, :net_min, :net_avg, :net_max]

  defstruct machine: "", date: "", time: "", data: %{}

  defp find_new_files(path, existing_files) do
    files = Path.wildcard(path)
    new_files = files -- existing_files

    Logger.debug "Files found while looking in directory #{path} are: #{inspect(files)}"
    Logger.info "The new files discovered are: #{inspect(new_files)}"
    %{:found => files, :new => new_files}
  end

  defp get_chunk_key(line) do
    line.machine <> line.date
  end


  defp get_chunk_filename_key(filename) do
    # the key should be the date portion of the filename so extract it
    #[^0-9]*(?<key>[0-9]{6}).*\.
    matches = Regex.named_captures(~r/[^0-9]*(?<key>[0-9]{6}).*\./, filename)
    matches["key"]
  end


  defp to_float(string_value) do
    cond do
      string_value == "" ->
        0.0
      true ->
        {value, _} = Float.parse(string_value)
        value
    end
  end

  ###################################################################################################################
  ## Client API

  def start_link(path) do
    case GenServer.start_link(__MODULE__, path, name: DataPoints) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  ###################################################################################################################
  ## Server Callbacks

  @impl true
  def init(_name) do
#    dir = "C:/temp/vmstats_data/"
    dir = "/mnt/VM-File-Storage/temp/vmstats_data/"
    type = "*.[cC][sS][vV]"
    path = dir <> type

    Logger.info("Starting DataPoints gen_server with path=#{inspect path}")

    schedule_work()

    state = %{path: path, existing_files: []}
    {:ok, state}
  end


  @impl true
  def handle_info(:work, state) do

    Logger.debug("Timer fired, state=#{inspect state}")

    # Find any new files and process them
    result = find_new_files(state.path, state.existing_files)
    case result do
      %{:found => _files, :new => []} -> Logger.debug("No new files found")
      %{:found => _files, :new => new_files} ->
        process_new_files1(new_files)
      %{} -> Logger.error("This should never happen. No match in handle_info")
    end

    schedule_work() # Reschedule once more

    # update the state
    newstate = put_in(state, [:existing_files], result.found)
    {:noreply, newstate}
  end

  # Scheulde a msg to be delivered to the process, effectively a timer
  defp schedule_work() do
    Process.send_after(self(), :work, @interval)
  end

  #################################################################################################################################
  # All the processing goes after this
  def process_new_files1(files) do
    files
    # ensure the files are ordered by the names so they can be grouped
    |> Enum.sort
    # create chunks of files all having the same date but different times
    |> Enum.chunk_by(&(get_chunk_filename_key(&1)))
    # enumerate through the chunks
    |> Flow.from_enumerable()
    # process the chunks in parallel
    |> Flow.partition(stages: 6)
    # enumerate through a chunk of files and process each one
    |> Flow.map(&process_group_of_files2(&1))
    # start the flow
    |> Flow.run()
    Logger.info "All files processed"
  end


  defp process_group_of_files2(file_list) do
      file_list
      |> Enum.map(&(process_file2(&1)))
  end

  defp process_file2(filename) do
    Logger.debug("File name to process=#{filename} in state=#{inspect self()}")
    filename
    |> File.stream!(read_ahead: 100_000)
    |> Stream.drop(1) # ignore the first line as it contains headers
    |> CSV.decode!(strip_fields: true, headers: @headers)
    |> Enum.chunk_by(&(get_chunk_key(&1)))
    |> Enum.map(&(process_chunk_for_same_machine_and_date(&1)))
  end

  defp process_chunk_for_same_machine_and_date(chunk) do

    [head | _tail] = chunk
    machine = head.machine
    date = head.date
    [month, day, year] = String.split(date, "/")
    {:ok, date_struct} = Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

    Logger.debug("Machine to process chunk for=#{inspect machine} with date=#{inspect date_struct}")

    state = DataPointsStore.start(machine, date_struct)

    state = store_chunk(chunk, machine, date, date_struct, state)

    Logger.debug("Final state for machine=#{inspect machine} with date=#{inspect date_struct} is state=#{inspect state}")

    :ok = DataPointsStore.stop(state)
  end


  defp store_chunk([], _machine, _date, _date_struct, state) do
    state
  end


  defp store_chunk(points, machine, date, date_struct, state) do

    [head | tail] = points

    [hours, minutes, seconds] = String.split(head.time, ":")
    time_in_s = (String.to_integer(hours) * 60 * 60) + (String.to_integer(minutes) * 60) + String.to_integer(seconds)

    point =
      %DataPoints{machine: machine,
        date: date_struct,
        time: time_in_s,
        data: [
          "mem_max", to_float(head.mem_max),
          "mem_min", to_float(head.mem_min),
          "mem_avg", to_float(head.mem_avg),
          "cpu_max", to_float(head.cpu_max),
          "cpu_min", to_float(head.cpu_min),
          "cpu_avg", to_float(head.cpu_avg),
          "net_max", to_float(head.net_max),
          "net_min", to_float(head.net_min),
          "net_avg", to_float(head.net_avg)
        ]
      }

    newstate = DataPointsStore.save_point(point, state)

    # recurse
    store_chunk(tail, machine, date, date_struct, newstate)
  end

end
