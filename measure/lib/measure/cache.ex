defmodule Measure.Cache do
  use GenServer

  def start_link(db_name) when is_atom(db_name) do
    GenServer.start_link(__MODULE__, db_name, name: __MODULE__)
  end

  @impl true
  def init(db_name) when is_atom(db_name) do
    :ets.new(db_name, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    :ets.insert(db_name, {:requests, 0})
    {:ok, db_name}
  end

  def increment() do
    GenServer.call(__MODULE__, :increment)
  end

  @impl true
  def handle_call(:increment, _from, db_name) do
    requests = :ets.update_counter(db_name, :requests, 1)
    {:reply, requests, db_name}
  end
end
