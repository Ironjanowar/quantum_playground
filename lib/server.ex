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

  def add_schedule(job_id, hours, minutes, function) when is_integer(hours) and is_integer(minutes) and is_function(function) do
    GenServer.cast @server, {:new_schedule, job_id, hours, minutes, function}
  end

  def get_state() do
    GenServer.call @server, :get_state
  end

  defp id_to_atom(id) when is_integer(id), do: id |> Integer.to_string |> String.to_atom

  # CASTS
  def handle_cast({:new_schedule, job_id, hours, minutes, function}, state) do
    with job_id <- id_to_atom(job_id),
    {:ok, schedule} <- Crontab.CronExpression.Parser.parse("#{minutes} #{hours} * * * *") do
      Logger.info "#{job_id} set!"
      Playground.Scheduler.new_job()
      |> Quantum.Job.set_name(job_id)
      |> Quantum.Job.set_timezone("Europe/Madrid")
      |> Quantum.Job.set_schedule(schedule)
      |> Quantum.Job.set_task(function)
      |> Playground.Scheduler.add_job()

      {:noreply, [job_id | state]}
    else
      _ -> {:noreply, state}
    end

  end

  # CALLS
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
