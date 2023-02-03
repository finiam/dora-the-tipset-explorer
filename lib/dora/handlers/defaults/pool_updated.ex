defmodule Dora.Handlers.Defaults.PoolUpdated do
  require Logger

  alias Dora.{Events, Projections, Repo}
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

      projection =
        Projections.get_event_projection_by(projection_id: address, projection_type: "loan")

      projection_fields =
        Map.update(projection.projection_fields, "repaid_amount", "0", fn old_amount ->
          Decimal.new(old_amount)
          |> Decimal.add(Decimal.new(topics_map["amount"]))
          |> Decimal.to_string()
        end)

      Projections.update_event_projection(address, %{
        projection_fields: projection_fields
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
end
