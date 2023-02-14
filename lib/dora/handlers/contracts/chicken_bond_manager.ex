defmodule Dora.Handlers.Contracts.ChickenBondManager do
  require Logger

  alias Dora.{Events, Projections, Repo}
  alias Dora.Utils

  def apply("bond_cancelled", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    bond_cancelled = %{
      bonder: topics_map["bonder"],
      bond_id: topics_map["bondId"],
      principalfil_amount: topics_map["principalfilAmount"],
      minfil_amount: topics_map["minfilAmount"],
      withdrawnfil_amount: topics_map["withdrawnfilAmount"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "bond_cancelled",
        contract_address: address,
        event_args: bond_cancelled
      })

      projection =
        Projections.get_event_projection_by(
          projection_id: topics_map["bondId"],
          projection_type: "bond_nft",
          contract_address: address
        )

      projection_fields = Map.put(projection.projection_fields, "status", "chickened_out")

      Projections.update_event_projection(address, topics_map["bondId"], "bond_nft", %{
        projection_fields: projection_fields
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end

  def apply("bond_claimed", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)

    bond_claimed = %{
      bonder: topics_map["bonder"],
      bond_id: topics_map["bondId"],
      fil_amount: topics_map["filAmount"],
      bfil_amount: topics_map["bfilAmount"],
      fil_surplus: topics_map["filSurplus"],
      chicken_in_fee_amount: topics_map["chickenInFeeAmount"],
      migration: topics_map["migration"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "bond_claimed",
        contract_address: address,
        event_args: bond_claimed
      })

      projection =
        Projections.get_event_projection_by(
          projection_id: topics_map["bondId"],
          projection_type: "bond_nft",
          contract_address: address
        )

      projection_fields = Map.put(projection.projection_fields, "status", "chickened_in")

      Projections.update_event_projection(address, topics_map["bondId"], "bond_nft", %{
        projection_fields: projection_fields
      })
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end

  def apply("bond_created", address, {_function, topics}) do
    topics_map = Utils.build_topics_maps(topics)
    id = topics_map["bondId"]

    bond_created = %{
      bonder: topics_map["bonder"],
      bond_id: id,
      amount: topics_map["amount"]
    }

    Repo.transaction(fn ->
      Events.create_event(%{
        event_type: "bond_created",
        contract_address: address,
        event_args: bond_created
      })

      Projections.insert_or_update_event_projection(
        [contract_address: address, projection_type: "bond_nft", projection_id: id],
        %{
          contract_address: address,
          projection_type: "bond_nft",
          projection_id: id,
          projection_fields: %{
            owner: topics_map["bonder"],
            status: "active",
            amount: topics_map["amount"]
          }
        }
      )
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
end
