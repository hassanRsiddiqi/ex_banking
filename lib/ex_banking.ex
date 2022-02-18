defmodule ExBanking do
  @moduledoc """
  Module to make transactions to a user.
  """
  alias ExBanking.{User, Transaction, Format}

  @type banking_error ::
          {:error,
           :wrong_arguments
           | :user_already_exists
           | :user_does_not_exist
           | :not_enough_money
           | :sender_does_not_exist
           | :receiver_does_not_exist
           | :too_many_requests_to_user
           | :too_many_requests_to_sender
           | :too_many_requests_to_receiver}

  @type banking_response ::
          :ok
          | {:ok, new_balance :: number}
          | {:ok, from_user_balance :: number, to_user_balance :: number}

  @doc """
  - Function creates new user in the system
  - New user has zero balance of any currency
  """
  @spec create_user(user :: String.t()) :: :ok | banking_error
  def create_user(user) when is_binary(user) do
    ExBanking.User.Supervisor.create_user(user)
  end

  def create_user(_), do: {:error, :wrong_arguments}

  @doc """
  - Increases user's balance in given currency by amount value
  - Returns new_balance of the user in given format
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def deposit(user, amount, currency) do
    case Transaction.new(:deposit, user, amount, currency) do
      %Transaction{} = transaction ->
        User.make_transaction(transaction)
        |> Format.response()

      error ->
        error
    end
  end

  @doc """
  - Decreases user's balance in given currency by amount value
  - Returns new_balance of the user in given format
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number} | banking_error
  def withdraw(user, amount, currency) do
    case Transaction.new(:withdraw, user, amount, currency) do
      %Transaction{} = transaction ->
        User.make_transaction(transaction)
        |> Format.response()

      error ->
        error
    end
  end

  @doc """
  - Returns balance of the user in given format
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number} | banking_error
  def get_balance(user, currency) do
    case Transaction.new(:balance, user, currency) do
      %Transaction{} = transaction ->
        User.make_transaction(transaction)
        |> Format.response()

      error ->
        error
    end
  end

  @doc """
  - Decreases from_user's balance in given currency by amount value
  - Increases to_user's balance in given currency by amount value
  - Returns balance of from_user and to_user in given format
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
  def send(from_user, to_user, amount, currency) do
    case Transaction.new(:send, from_user, to_user, amount, currency) do
      %Transaction{} = transaction ->
        User.make_transaction(transaction)
        |> Format.response()

      error ->
        error
    end
  end
end
