defmodule ExBanking.FormatTest do
  use ExUnit.Case
  alias ExBanking.Format

  describe "response/1" do
    test "returns money as float" do
      result =
        {:ok, 1234}
        |> Format.response()

      assert(result == {:ok, 12.34})
    end

    test "returns 2 amounts as float" do
      result =
        {:ok, 4545, 4999}
        |> Format.response()

      assert(result == {:ok, 45.45, 49.99})
    end
  end
end
