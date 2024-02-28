defmodule Measure do
  @moduledoc """
    Measure PostgreSQL Sharding perfomance.
  """

  require Logger
  alias Measure.TaskSupervisor
  alias Measure.Cache

  @threads 150

  def run_insert_measure() do
    write_time()
    make_requests(&measure_books_insert/0)
  end

  def run_select_measure() do
    write_time()
    make_requests(&measure_books_select/0)
  end

  defp make_requests(requests_fun, threads \\ @threads) do
    if @threads > 0 do
      Enum.each(1..threads, fn _ ->
        Task.Supervisor.start_child(TaskSupervisor, fn -> requests_fun.() end)
      end)
    end

    count = Task.Supervisor.children(TaskSupervisor) |> Enum.count

    if count < @threads do
      make_requests(requests_fun, @threads - count)
    else
      make_requests(requests_fun, 0)
    end
  end

  defp measure_books_select() do
    case select_book() do
      %Postgrex.Result{} ->
        requests = Cache.increment()
        Logger.info("Requests: #{requests}")

        if requests == 1_000_000 do
          write_time()
        end

      error ->
        Logger.error(inspect(error))
    end
  end

  defp select_book() do
    Postgrex.query!(:postgrex, "SELECT * FROM books where id = #{Enum.random(1..1_000_000)};", [])
  end

  defp measure_books_insert() do
    case insert_book() do
      %Postgrex.Result{} ->
        requests = Cache.increment()
        Logger.info("Requests: #{requests}")

        if requests == 1_000_000 do
          write_time()
        end

      error ->
        Logger.error(inspect(error))
    end
  end

  defp insert_book() do
    year = Enum.random(1900..2024)
    title = random_string!(10)
    author = random_string!(10)
    category_id = Enum.random(1..10)

    Postgrex.query!(:postgrex, "INSERT INTO books (title, category_id, author, year) VALUES ('#{title}', #{category_id}, '#{author}', #{year});", [])
  end

  defp random_string!(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.encode64()
    |> String.slice(0, length)
  end

  defp write_time() do
    File.open("./time.txt", [:write], fn file ->
      IO.write(file, DateTime.utc_now())
    end)
  end
end
