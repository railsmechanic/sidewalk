defmodule Sidewalk do
  @moduledoc ~S"""
  Sidewalk is an Elixir client which is compatible with Sidekiq, the »efficient background processing library for Ruby«.
  It can be used to enqueue jobs for later processing alongside e.g. with an already existing Ruby application.
  For more information about Sidekiq please refer to http://sidekiq.org.

  ## Supported features

  * Redis namespaces as already known with Sidekiq
  * Ability to configure the Redis server connection details
  * Ability to configuration a Redis pool size
  * Enqueuing jobs to be executed immediately
  * Enqueuing jobs to be executed in X seconds
  * Enqueuing jobs to be executed at a specific time

  ## Configuration example

      config :sidewalk,
        host: "localhost",
        port: 6379,
        password: "you password",
        namespace: "your_namespace",
        database: 0,
        pool_size: 10


  ## Adding sidewalk to your applications

      def application do
        [applications: [:sidewalk],
         mod: {YourApplication, []}]
      end


  To use Sidewalk you need to create a `%Sidewalk.Job{}` and enqueue it with one of the enqueue functions.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      :poolboy.child_spec(:sidewalk_pool, pool_options(), redix_options())
    ]

    opts = [strategy: :one_for_one, name: Sidewalk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp pool_options do
    [
      name: {:local, :sidewalk_pool},
      worker_module: Redix,
      size: Application.get_env(:sidewalk, :pool_size, 5),
      max_overflow: 0
    ]
  end

  defp redix_options do
    [
      host: Application.get_env(:sidewalk, :host, "localhost"),
      port: Application.get_env(:sidewalk, :port, 6379),
      password: Application.get_env(:sidewalk, :password),
      database: Application.get_env(:sidewalk, :database, 0)
    ]
  end
end
