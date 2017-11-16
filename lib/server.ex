defmodule Playground.Server do
  use GenServer
  require Logger

  @server :server

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: @server]
  end

  def init(:ok) do
    Logger.info "Server started"
    {:ok, []}
  end

  def add_schedule(job_id, hour, minute, function) when is_integer(hour) and is_integer(minute) and is_function(function) do
    GenServer.cast @server, {:new_schedule, job_id, hour, minute, function}
  end

  def get_state() do
    GenServer.call @server, :get_state
  end

  defp id_to_atom(id) when is_integer(id), do: id |> Integer.to_string |> String.to_atom

  # CASTS
  def handle_cast({:new_schedule, job_id, hour, minute, function}, state) do
    Playground.Scheduler.new_job()
    |> Quantum.Job.set_name(id_to_atom(job_id))
    |> Quantum.Job.set_timezone("Europe/Madrid")
    |> Quantum.Job.set_schedule(~e[#{minute} #{hour} * * *])
    |> Quantum.Job.set_task(function)
    |> Playground.Scheduler.add_job()

    {:noreply, [job_id | state]}
  end

  # CALLS
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
