defmodule Dora.Handlers.<%= @module_prefix %>.<%= @module_name %> do
  require Logger

  alias Dora.{Events, Projections, Repo}
  alias Dora.Utils

  # What other things can you do inside an handler, and not generated here?
  #
  # - You may want to add a projection event, using `Projections`. Example:
  #
  #    Projections.insert_or_update_event_projection(
  #      [contract_address: address, projection_type: "nft", projection_id: id],
  #      %{
  #        contract_address: address,
  #        projection_type: "nft",
  #        projection_id: id,
  #        projection_fields: %{owner: new_owner}
  #      }
  #    )
  #
  #  The code above creates or updates the owner of an NFT everytime a
  #  Transfer Event is detected. Be sure to keep/add DB interactions inside a Transaction!
  #
  # - You can kickstart a concurrent exploration of a new Smart Contract, using:
  #
  #    `Dora.start_explorer_instance(SOME_ADDRESS, ABI_PATH)`
  #
  # - Many other things.
  <%= for {type, args} <- @abi do %>
  def apply(<%= if not is_nil(@address), do: "#{inspect Macro.underscore(type)}, "  %>address, {_function, topics}, original_event) do
    topics_map = Utils.build_topics_maps(topics)

    <%= Macro.underscore(type) %> = %{
      <%= for {field, i} <- Enum.with_index(args) do %><%= Macro.underscore(field.name) %>: topics_map["<%= field.name %>"]<%= if i + 1 != length(args), do: ",", else: "\n    }" %>
      <% end %>
    Repo.transaction(fn ->
      # This will create a new DB entry with for this event
      Events.create_event(%{
        event_type: "<%= Macro.underscore(type) %>",
        contract_address: address,
        event_args: <%= Macro.underscore(type) %>,
        block_hash: original_event["blockHash"],
        tx_hash: original_event["transactionHash"],
        log_index: original_event["logIndex"]
      })

      # Other code you may want to add inside the Transaction
      # Check the comment block on top
    end)
    |> case do
      {:ok, _} = result -> result
      error -> Logger.error("Failed to run transaction. Error: #{inspect(error)}")
    end
  end
  <% end %>
end
