defmodule Dora.Handlers.Contracts.Pool do
  require Logger

  alias Dora.{Events, Projections, Repo}
  alias Dora.Utils

  def apply("lender_deposit", address, {_function, topics}, original_event) do
    topics_map = Utils.build_topics_maps(topics)

    lender_deposit = %{
      from: topics_map["from"],
      value: topics_map["value"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "lender_deposit",
        contract_address: address,
        event_args: lender_deposit,
        block_hash: original_event["blockHash"],
        tx_hash: original_event["transactionHash"],
        log_index: original_event["logIndex"]
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end

  def apply("new_broker_deployed", address, {_function, topics}, original_event) do
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
        event_args: new_broker_deployed,
        block_hash: original_event["blockHash"],
        tx_hash: original_event["transactionHash"],
        log_index: original_event["logIndex"]
      })

      Projections.create_event_projection(%{
        projection_type: "loan",
        projection_id: topics_map["broker"],
        projection_fields: %{
          owner: topics_map["storageProviderOwner"],
          total_amount: topics_map["amount"],
          repaid_amount: "0"
        },
        contract_address: address
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

  def apply("storage_provider_deposit", address, {_function, topics}, original_event) do
    topics_map = Utils.build_topics_maps(topics)

    storage_provider_deposit = %{
      from: topics_map["from"],
      value: topics_map["value"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "storage_provider_deposit",
        contract_address: address,
        event_args: storage_provider_deposit,
        block_hash: original_event["blockHash"],
        tx_hash: original_event["transactionHash"],
        log_index: original_event["logIndex"]
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
end
