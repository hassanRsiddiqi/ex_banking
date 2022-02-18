defmodule ExBanking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: true
    # List all child processes to be supervised
    children = [
      supervisor(ExBanking.User.Supervisor, []),
      supervisor(Eternal, [
        ExBanking.User.Vault,
        [:set, {:read_concurrency, true}, {:write_concurrency, true}]
      ]),
      {Registry, keys: :unique, name: Registry.User}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExBanking.Application]
    Supervisor.start_link(children, opts)
  end
end
