defmodule ExBanking.Format do
  @moduledoc """
  Show the money upto 2 decimals.
  """

  @doc """
  Returns in float.
  """
  def response({:ok, amount}), do: {:ok, to_float(amount)}

  def response({:ok, sender_amount, receiver_amount}) do
    {:ok, to_float(sender_amount), to_float(receiver_amount)}
  end

  def response({:error, _} = error), do: error

  defp to_float(amount) when is_integer(amount) do
    amount / 100
  end
end
