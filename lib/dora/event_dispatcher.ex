defmodule Dora.EventDispatcher do
  @moduledoc false

  require Logger

  def dispatch(contract_address, {:error, decoded_event}, _) do
    Logger.error(
      "Couldn't find a matching Event for #{contract_address}: #{inspect(decoded_event)}"
    )
  end

  def dispatch(contract_address, {abi_selector, decoded_event}, original_event) do
    event_type = abi_selector.function

    event_type
    |> Macro.underscore()
    |> handle(contract_address, {abi_selector, decoded_event}, original_event)
  end

  def handle("storage_provider_deposit", "0xb27d23387324401f829c8c0b73a3df10a72c4080", event) do
    Dora.Handlers.Contracts.Pool.apply(
      "storage_provider_deposit",
      "0xb27d23387324401f829c8c0b73a3df10a72c4080",
      event
    )
  end

  def handle("new_broker_deployed", "0xb27d23387324401f829c8c0b73a3df10a72c4080", event) do
    Dora.Handlers.Contracts.Pool.apply(
      "new_broker_deployed",
      "0xb27d23387324401f829c8c0b73a3df10a72c4080",
      event
    )
  end

  def handle("lender_deposit", "0xb27d23387324401f829c8c0b73a3df10a72c4080", event) do
    Dora.Handlers.Contracts.Pool.apply(
      "lender_deposit",
      "0xb27d23387324401f829c8c0b73a3df10a72c4080",
      event
    )
  end

  # If we want to deal with the event without worrying on the address
  # Default behaviour for all Transfer events
  #
  # Remove this if you don't need it in your handlers
  def handle("transfer", address, event, original_event) do
    Dora.Handlers.Defaults.Transfer.apply(address, event, original_event)
  end

  def handle("pool_updated", address, event) do
    Dora.Handlers.Defaults.PoolUpdated.apply(address, event)
  end

  def handle(type, address, _event) do
    Logger.warning("Ignoring event #{type} from #{address}.")
  end
end
