defmodule Dora.Handlers.Defaults.PoolUpdated do
  require Logger

  alias Dora.{Events, Repo}
  alias Dora.Handlers.Utils

  def apply(address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    pool_updated = %{
      storage_provider: topics_map["storageProvider"],
      pool: topics_map["pool"],
      amount: topics_map["amount"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "pool_updated",
        contract_address: address,
        event_args: pool_updated
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
end
