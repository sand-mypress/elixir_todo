# Todo.System supervisor
#   |- Todo.Database supervisor
#       |- Todo.DatabaseWorker1 worker
#       |- Todo.DatabaseWorker2 worker
#       |- Todo.DatabaseWorker3 worker

defmodule Todo.Database do
  @pool_size 3
  @db_folder "./persist"

  def start_link do
    IO.puts("Starting to-do Database")
    File.mkdir_p!(@db_folder)
    children = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one,  name: __MODULE__)
  end

  defp worker_spec(worker_id) do
    # {module-name, start_link-argument}
    default_worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}
    # child_spec(module_or_map, overrides)
    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def store(worker_id, data) do
    worker_id
    |> choose_worker()
    |> Todo.DatabaseWorker.store(worker_id, data)
  end

  def get(worker_id) do
    IO.puts("get for #{worker_id}")
    worker_id
    |> choose_worker()
    |> Todo.DatabaseWorker.get(worker_id)
  end

  defp choose_worker(worker_id) do
    :erlang.phash2(worker_id, @pool_size) + 1
  end
end
