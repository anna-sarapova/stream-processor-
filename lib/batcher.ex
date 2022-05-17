defmodule Batcher do
  use GenServer
  require Logger

  @records_size 99
  @timer 1000

  def start_module() do
    IO.inspect("Starting Batcher")
    {:ok, mongo_db} = Mongo.start_link(url: "mongodb://localhost:27017/Stream_Processor")
    timer_ref =  restart_timer()
    database_state = 1
    GenServer.start_link(__MODULE__, %{batch: [], mongo_db: mongo_db, records_per_interval: 0, timer_ref: timer_ref, database_state: database_state}, name: __MODULE__)
  end

  def receive_record(record) do
    GenServer.cast(__MODULE__, {:add_in_state, record})
  end

  def restart_timer() do
    Process.send_after(self(), :reset_timer, @timer)
  end

  def send_to_database(records, mongo_db) do
    batch_size = Kernel.length(records)
    Mongo.insert_many(mongo_db, "tweets", get_tweet(records))
    Mongo.insert_many(mongo_db, "user", get_user(records))
#    Logger.info("Batcher: the records were sent, batch size #{inspect(batch_size)}", ansi_color: :light_blue)
  end

  def get_user(records) do
    Enum.map(records, fn record -> record.user end)
  end

  def get_tweet(records) do
    Enum.map(records, fn record -> record.tweet_data end)
  end

  def send_notification() do
    GenServer.cast(__MODULE__, :change_db_state)
  end

  def start_timer() do
    Process.send_after(self(), :timer, 2000)
  end

  def init(state) do
    start_timer()
    {:ok, state}
  end

  def handle_cast({:add_in_state, record}, state) do
    records_list = [record | state.batch]
    record_counter = state.records_per_interval + 1
    case state.records_per_interval >= @records_size do
      true ->
        send_to_database(records_list, state.mongo_db)
        Process.cancel_timer(state.timer_ref)
        timer_ref = restart_timer()
        {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref, database_state: state.database_state}}
      false ->
        {:noreply, %{batch: records_list, mongo_db: state.mongo_db, records_per_interval: record_counter , timer_ref: state.timer_ref, database_state: state.database_state}}
    end
  end

  def handle_info(:reset_timer, state) do
    if Kernel.length(state.batch) == 0 do
      timer_ref = restart_timer()
      {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref, database_state: state.database_state}}
    else
      send_to_database(state.batch, state.mongo_db)
      timer_ref = restart_timer()
      {:noreply, %{batch: [], mongo_db: state.mongo_db, records_per_interval: 0, timer_ref: timer_ref, database_state: state.database_state}}
    end
  end

  def handle_cast(:change_db_state, state) do
    state_list = [0, 1]
    new_state = Enum.random(state_list)
    if state.database_state != new_state do
      Aggregator.receive_notification(new_state)
      Logger.info("Batcher: New state is #{inspect(new_state)}")
      {:noreply, %{state | database_state: new_state}}
    else
      Logger.info("Batcher: Database state is still #{inspect(state.database_state)}")
      {:noreply, state}
    end
  end

  def handle_info(:timer, state) do
    start_timer()
    send_notification()
    {:noreply, state}
  end

end
