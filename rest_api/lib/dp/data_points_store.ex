defmodule DataPointsStore do

  require Logger

  ## Constants
  @empty_map %{}

  def get_name(machine, year, month, day) do
    "#{machine}-#{year}-#{month}-#{day}"
  end


  def start(machine, %Date{} = date) do
    name = get_name(machine, date.year, date.month, date.day)
    Logger.debug("Starting DataPointsStore with name=#{inspect name}")


#    dir = "./DataPointsStore-files/" <> machine
    dir = "/mnt/VM-File-Storage/temp/vmstats_data/DataPointsStore-files/" <> machine
    filename = dir <> "/#{name}.dets"
    Logger.info("Starting store with filename=#{inspect filename}")

    # read the file
    # if it does not exist ignore it
    # if the dir does not exist then mkdir
    # if it exists return the data
    data = case File.read(filename) do
      {:ok, ""} ->
        # empty file
        @empty_map
      {:ok, bin} ->
        try do
          :erlang.binary_to_term(bin)
        rescue
          _ ->
            Logger.warn("Data read from file=#{filename} cannot be converted to term using erlang:bin_to_term. Data read from file is: #{inspect bin}. Setting data to empty map which will cause data loss.")
            @empty_map
        end
      {:error, reason} ->
        Logger.debug("File read error, reason=#{inspect reason}. This is expected if the file does not exist etc")
        :ok = File.mkdir_p(dir)
        @empty_map
    end

    Logger.debug("Initialized data store to #{inspect data}")
    %{filename: filename, data: data}
  end


  def stop(state) do
    Logger.info("Stopping store with filename=#{inspect state.filename}")
    bin = :erlang.term_to_binary(state.data)
    File.write!(state.filename, bin)
    :ok
  end


  # save data in the store
  def save(type, time, value, state) do
    Logger.debug("Saving for #{state.filename}, data=#{inspect state}")

    newstate = server_save(type, time, value, state)

    Logger.debug("newstate=#{inspect newstate}")
    newstate
  end


  # save data in the store
  def save_point(point, state) do
    Logger.debug("Saving point for #{state.filename}, data=#{inspect point}")

    # recursivly call save in order to update the state correctly
    newstate = server_save(point.data, point.time, state)

    Logger.debug("newstate=#{inspect newstate}")
    newstate
  end


  defp server_save([], _time, state) do
    state
  end


  defp server_save(list, time, state) do
    [key, value | tail] = list
    newstate = put_in(state, Enum.map([:data, key, time], &Access.key(&1, %{})), value)
    server_save(tail, time, newstate)
  end


  defp server_save(type, time, value, state) do
    # since it is not possible to use put_in when the key or any intermediate keys do not exist, the function
    # below adds the newdata if it does not exist or updates it if it does
    put_in(state, Enum.map([:data, type, time], &Access.key(&1, %{})), value)
  end


  # retireve data from the store given its type
  def get(type, state) do
    Logger.debug("Get for type=#{inspect type} when state=#{inspect state}")
    value = get_in(state, [:data, type])
    Logger.debug("Get value retrieved is = #{inspect value}")
    value
  end


  # empty any data that is in the store and throw it away
  def empty(type, state) do
    Logger.debug("Empty for type=#{inspect type}")

    # since it is not possible to use put_in when the key or any intermediate keys do not exist, the function
    # below adds the newdata if it does not exist or udates it if it does
    put_in(state, Enum.map([:data, type], &Access.key(&1, %{})), @empty_map)
  end


  # empty any data that is in the store and throw it away
  def empty_all(state) do
    Logger.debug("Empty_all")

    put_in(state, [:data], @empty_map)
  end

end
