defmodule StreamProcessor do
  use Application

  @impl true
  def start(_type, _args) do
    IO.inspect("The Application has started")
    url1 = "http://localhost:4000/tweets/1"
    url2 = "http://localhost:4000/tweets/2"

    children = [
      %{
        id: Router,
        start: {Router, :start_module, []}
      },
      %{
        id: StreamReader1,
        start: {StreamReader, :start_connection, [url1]}
      },
      %{
        id: StreamReader2,
        start: {StreamReader, :start_connection, [url2]}
      },
    ]

    opts = [strategy: :one_for_one, max_restarts: 100, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
