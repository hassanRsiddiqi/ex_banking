defmodule ExBankingTest do
  use ExUnit.Case, async: true

  @ets ExBanking.User.Vault
  @bytes Enum.concat([?a..?z, ?A..?Z, ?0..?9]) |> List.to_string()

  setup_all do
    random = fn length ->
      for _ <- 1..length, into: <<>> do
        index = :rand.uniform(byte_size(@bytes)) - 1
        <<:binary.at(@bytes, index)>>
      end
    end

    [random: random]
  end

  setup context do
    random = context[:random]
    name = random.(8)
    ExBanking.create_user(name)

    [name: name, random: random]
  end

  describe "create_user/1" do
    test "creates a new user" do
      result = ExBanking.create_user("create_user")

      assert(result == :ok)
    end

    test "returns error when user already exists", context do
      name = context[:name]
      result = ExBanking.create_user(name)
      assert(result == {:error, :user_already_exists})
    end
  end

  describe "deposit/3" do
    test "Increases user's balance in not existing currency by amount value", context do
      name = context[:name]
      currency = context[:random].(9)
      ExBanking.deposit(name, 23, currency)

      [{_, result}] = :ets.lookup(@ets, {name, currency})

      assert(result === 2300)
    end

    test "Increases user's balance in existing currency by amount value", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      ExBanking.deposit(name, 23.021, "BTC")

      [{_, result}] = :ets.lookup(@ets, {name, "BTC"})

      assert(result === 4602)
    end

    test "Returns new_balance of the user in given format", context do
      name = context[:name]
      result = ExBanking.deposit(name, 23.23, "BTC")

      assert(result == {:ok, 23.23})
    end

    test "Returns error if user does not exists" do
      result = ExBanking.deposit("not_existent", 23, "BTC")

      assert(result == {:error, :user_does_not_exists})
    end
  end

  describe "withdraw/3" do
    test "returns error in not existing currency by amount value", context do
      name = context[:name]
      result = ExBanking.withdraw(name, 23, "BTC")

      assert(result == {:error, :not_enough_money})
    end

    test "decreases user's balance in existing currency by amount value", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      ExBanking.withdraw(name, 20.43, "BTC")

      [{_, result}] = :ets.lookup(@ets, {name, "BTC"})

      assert(result === 257)
    end

    test "returns new_balance of the user in given format", context do
      name = context[:name]
      ExBanking.deposit(name, 23.54, "BTC")
      result = ExBanking.withdraw(name, 20, "BTC")

      assert(result == {:ok, 3.54})
    end

    test "returns error if user does not exists" do
      result = ExBanking.withdraw("not_existent", 23, "BTC")

      assert(result == {:error, :user_does_not_exists})
    end

    test "returns error if not enough money is in user balance", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      result = ExBanking.withdraw(name, 40, "BTC")

      assert(result == {:error, :not_enough_money})
    end
  end

  describe "get_balance/2" do
    test "returns balance of the user in given format", context do
      name = context[:name]
      ExBanking.deposit(name, 23.0004, "BTC")

      result = ExBanking.get_balance(name, "BTC")

      assert(result === {:ok, 23.0})
    end

    test "returns balance of user from not existent currency", context do
      name = context[:name]
      result = ExBanking.get_balance(name, "BTC")

      assert(result === {:ok, 0.0})
    end

    test "returns error if user does not exist" do
      result = ExBanking.get_balance("not_existent", "BTC")

      assert(result == {:error, :user_does_not_exists})
    end
  end

  describe "send/4" do
    test "decreases from_user's balance in given currency by amount value", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      name2 = context[:random].(8)
      ExBanking.create_user(name2)
      ExBanking.deposit(name2, 23, "BTC")

      ExBanking.send(name, name2, 22.05, "BTC")

      [{_, result}] = :ets.lookup(@ets, {name, "BTC"})

      assert(result === 95)
    end

    test "increases to_user's balance in given currency by amount value", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")

      name2 = context[:random].(8)
      ExBanking.create_user(name2)
      ExBanking.deposit(name2, 23, "BTC")

      ExBanking.send(name, name2, 23, "BTC")

      [{_, result}] = :ets.lookup(@ets, {name2, "BTC"})

      assert(result === 4600)
    end

    test "returns balance of from_user and to_user in given format", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      name2 = context[:random].(8)
      ExBanking.create_user(name2)
      ExBanking.deposit(name2, 23, "BTC")

      result = ExBanking.send(name, name2, 23, "BTC")

      assert(result == {:ok, 0, 46.00})
    end

    test "returns error when sender does not exists", context do
      name = context[:name]
      name2 = context[:random].(8)
      result = ExBanking.send(name2, name, 23, "BTC")

      assert(result == {:error, :sender_does_not_exists})
    end

    test "returns error when receiver does not exists", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")

      name2 = context[:random].(8)
      result = ExBanking.send(name, name2, 23, "BTC")

      assert(result == {:error, :receiver_does_not_exists})
    end

    test "returns error when there is not enough money", context do
      name = context[:name]
      ExBanking.deposit(name, 23, "BTC")
      name2 = context[:random].(8)
      ExBanking.create_user(name2)
      ExBanking.deposit(name2, 23, "BTC")

      result = ExBanking.send(name, name2, 23.01, "BTC")

      assert(result == {:error, :not_enough_money})
    end
  end

  describe "performance tests" do
    test "can handle 10 requests without a problem", context do
      name = context[:name]
      currency = context[:random].(8)

      result =
        Enum.reduce(0..43, [], fn _, acc ->
          [Task.async(fn -> ExBanking.deposit(name, 1, currency) end) | acc]
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn {res, _} -> res == :ok end)

      assert(result == 10)
    end

    test "returns error with more than 10 pending requests", context do
      name = context[:name]
      currency = context[:random].(8)

      result =
        Enum.reduce(0..43, [], fn _, acc ->
          [Task.async(fn -> ExBanking.deposit(name, 1, currency) end) | acc]
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn {res, _} -> res == :error end)

      assert(result == 34)
    end
  end
end
