defmodule ExBanking.TransactionTest do
  use ExUnit.Case, async: true
  alias ExBanking.Transaction
  require ExBanking.Transaction

  setup_all do
    ExBanking.User.Supervisor.create_user("user1")
    ExBanking.User.Supervisor.create_user("user2")

    :ok
  end

  describe "new/4" do
    test "makes a deposit transaction from correct parameters" do
      result = Transaction.new(:withdraw, "user1", 23, "BTC")

      should_be = %Transaction{type: :withdraw, receiver: "user1", amount: 2300, currency: "BTC"}
      assert(result == should_be)
    end

    test "returns error when user is not a binary" do
      result = Transaction.new(:withdraw, 9090, 23, "BTC")

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when currency is not a binary" do
      result = Transaction.new(:withdraw, "user1", 23, 3434)

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when amount is lower than 0" do
      result = Transaction.new(:withdraw, "user1", -23, "BTC")

      assert(result == {:error, :wrong_arguments})
    end
  end

  describe "new/3" do
    test "makes a balance transaction from correct parameters" do
      result = Transaction.new(:balance, "user1", "BTC")

      should_be = %Transaction{type: :balance, receiver: "user1", currency: "BTC"}
      assert(result == should_be)
    end

    test "returns error when user is not a binary" do
      result = Transaction.new(:balance, 9090, "BTC")

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when currency is not a binary" do
      result = Transaction.new(:balance, "user1", 3434)

      assert(result == {:error, :wrong_arguments})
    end
  end

  describe "new/5" do
    test "makes a send transaction from correct parameters" do
      result = Transaction.new(:send, "user1", "user2", 23, "BTC")

      should_be = %Transaction{
        type: :send,
        receiver: "user2",
        sender: "user1",
        amount: 2300,
        currency: "BTC"
      }

      assert(result == should_be)
    end

    test "returns error when sender is not a binary" do
      result = Transaction.new(:send, 9090, "user2", 23, "BTC")

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when sender does not exists" do
      result = Transaction.new(:send, "not_exists", "user2", 23, "BTC")

      assert(result == {:error, :sender_does_not_exists})
    end

    test "returns error when receiver is not a binary" do
      result = Transaction.new(:send, 9090, "user2", 23, "BTC")

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when receiver does not exists" do
      result = Transaction.new(:send, "user2", "not_exists", 23, "BTC")

      assert(result == {:error, :receiver_does_not_exists})
    end

    test "returns error when currency is not a binary" do
      result = Transaction.new(:send, "user1", "user2", 23, 3434)

      assert(result == {:error, :wrong_arguments})
    end

    test "returns error when amount is lower than 0" do
      result = Transaction.new(:send, "user1", "user2", -23, "BTC")

      assert(result == {:error, :wrong_arguments})
    end
  end

  describe "defguard are_binaries/2" do
    test "returns true when both are binaries" do
      result = Transaction.are_binaries("a", "b")

      assert(result == true)
    end

    test "resturns false when 1 of them is not a binary" do
      result = Transaction.are_binaries(1, "2")

      assert(result == false)
    end
  end

  describe "defguard are_binaries/3" do
    test "returns true when both are binaries" do
      result = Transaction.are_binaries("a", "b", "C")

      assert(result == true)
    end

    test "resturns false when 1 of them is not a binary" do
      result = Transaction.are_binaries(1, "2", "c")

      assert(result == false)
    end
  end
end
