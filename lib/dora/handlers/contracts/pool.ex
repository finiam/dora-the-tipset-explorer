defmodule Dora.Handlers.Contracts.Pool do
  require Logger

  alias Dora.{Events, Repo}
  alias Dora.Handlers.Utils

  def apply("lender_deposit", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    lender_deposit = %{
      from: topics_map["from"],
      value: topics_map["value"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "lender_deposit",
        contract_address: address,
        event_args: lender_deposit
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end

  def apply("new_broker_deployed", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    new_broker_deployed = %{
      broker: topics_map["broker"],
      pool: topics_map["pool"],
      storage_provider_owner: topics_map["storageProviderOwner"],
      storage_provider_miner: topics_map["storageProviderMiner"],
      amount: topics_map["amount"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "new_broker_deployed",
        contract_address: address,
        event_args: new_broker_deployed
      })
    end)
    |> case do
      {:ok, _} = result ->
        Dora.start_explorer_instance(topics_map["broker"], "priv/abis/broker.json")
        result

      error ->
        Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end

  def apply("storage_provider_deposit", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    storage_provider_deposit = %{
      from: topics_map["from"],
      value: topics_map["value"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "storage_provider_deposit",
        contract_address: address,
        event_args: storage_provider_deposit
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
end
