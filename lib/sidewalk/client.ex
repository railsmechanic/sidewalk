defmodule Sidewalk.Client do
  @moduledoc ~S"""
  The Client module contains functions to interact with the Redis server and to enqueue jobs in the format Sidekiq uses.
  Like Sidekiq or Resque it supports three types of enqueuing.

  * Enquing with an immediate execution
  * Enquing with an execution delay defined in seconds
  * Enquing with an explicit execution at a given unix timestamp

  For more information of the structure of a Sidewalk job, please have a look at the `Job` module.
  """

  @type job           :: Sidewalk.Job.t
  @type enqueue_delay :: Integer.t
  @type enqueue_time  :: Integer.t
  @type response      :: {:ok, String.t} | {:error, String.t}

  @doc """
  Jobs enqueued with this function will be executed by Sidekiq as soon as possible.

  ## Example
      # Enqueue a job which should be executed immediately
      job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
      {:ok, jid} = Sidewalk.Client.enqueue(job) # => jid: "2f87a952ced00ea6cdd61245"
  """
  @spec enqueue(job) :: response
  def enqueue(job=%Sidewalk.Job{}) do
    with {:ok, normalized_job} <- normalize_job(job), do: atomic_push(normalized_job)
  end
  def enqueue(_) do
    {:error, "Job must be a Sidewalk.Job with at least 'class' and 'args' set: %Sidewalk.Job{class: 'SomeWorker', args: ['bob', 1, %{foo: 'bar'}]}"}
  end

  @doc """
  Jobs enqueued with this function will be executed by Sidekiq after a defined delay in seconds.

  ## Example
      # Enquing a job which would be executed in 2 minutes (120 seconds) from now
      job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
      {:ok, jid} = Sidewalk.Client.enqueue_in(job, 120) # => jid: "a805893e8bd98bf965d1dd54"
  """
  @spec enqueue_in(job, enqueue_delay) :: response
  def enqueue_in(job, enqueue_in_seconds \\ 60)
  def enqueue_in(job=%Sidewalk.Job{}, enqueue_in_seconds) when is_integer(enqueue_in_seconds) and enqueue_in_seconds > 0 do
    enqueue_at(job, (current_unix_timestamp() + enqueue_in_seconds))
  end
  def enqueue_in(job=%Sidewalk.Job{}, enqueue_in_seconds) when is_integer(enqueue_in_seconds) and enqueue_in_seconds <= 0 do
    enqueue(job)
  end
  def enqueue_in(_,_) do
    {:error, "Job must be a Sidewalk.Job with at least 'class' and 'args' set: %Sidewalk.Job{class: 'SomeWorker', args: ['bob', 1, %{foo: 'bar'}]} and a valid 'enqueue in' delay in seconds greater than 0"}
  end

  @doc """
  Jobs enqueued with this function will be executed by Sidekiq at a given unix timestamp.

  ## Example
      # Enquing a job which would be executed at 31th December 2018 (unix timestamp: 1546293600)
      job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
      {:ok, jid} = Sidewalk.Client.enqueue_at(job, 1546293600) # => jid: "d6ceac7d6c42d35ff6cac8a0"
  """
  @spec enqueue_at(job, enqueue_time) :: response
  def enqueue_at(job, enqueue_at_timestamp \\ (current_unix_timestamp() + 60))
  def enqueue_at(job=%Sidewalk.Job{}, enqueue_at_timestamp) when is_number(enqueue_at_timestamp) and enqueue_at_timestamp > 1_000_000_000 do
    if enqueue_at_timestamp <= current_unix_timestamp() do
      enqueue(job)
    else
      with {:ok, normalized_job} <- normalize_job(job), do: atomic_push(normalized_job, enqueue_at_timestamp)
    end
  end
  def enqueue_at(_,_) do
    {:error, "Job must be a Sidewalk.Job with at least 'class' and 'args' set: %Sidewalk.Job{class: 'SomeWorker', args: ['bob', 1, %{foo: 'bar'}]} and a valid 'enqueue at' formated as unix timestamp"}
  end


  ############################################################
  ## --> HELPER FUNCTIONS
  @spec normalize_job(job) :: {:ok, job} | {:error, String.t}
  defp normalize_job(job) do
    case job do
      %Sidewalk.Job{class: class} when not is_binary(class) or (is_binary(class) and byte_size(class) <= 0) ->
        {:error, "Job class must be a valid String representation of the class name"}
      %Sidewalk.Job{queue: queue} when not is_binary(queue) or (is_binary(queue) and byte_size(queue) <= 0) ->
        {:error, "Job queue must be a valid String representation of the queue name"}
      %Sidewalk.Job{args: args} when not is_list(args) ->
        {:error, "Job args must be a List"}
      %Sidewalk.Job{class: class, args: args} when is_binary(class) and byte_size(class) > 0 and is_list(args) ->
        {:ok, %{job | jid: random_jid(), created_at: current_unix_timestamp()}}
      _ ->
        {:error, "Job must be a Sidewalk.Job with at least 'class' and 'args' set: %Sidewalk.Job{class: 'SomeWorker', args: ['bob', 1, %{foo: 'bar'}]}"}
    end
  end

  @spec atomic_push(job) :: response
  defp atomic_push(job) when is_map(job) do
    case Poison.encode(%{job | enqueued_at: current_unix_timestamp()}) do
      {:ok, encoded_job} ->
        :poolboy.transaction(:sidewalk_pool, fn(conn) ->
          with  {:ok, _} <- Redix.command(conn, ~w(MULTI)),
                {:ok, _} <- Redix.command(conn, ["SADD", namespacify("queues"), job.queue]),
                {:ok, _} <- Redix.command(conn, ["LPUSH", namespacify("queue:#{job.queue}"), encoded_job]),
                {:ok, _} <- Redix.command(conn, ~w(EXEC)),
          do: {:ok, job.jid}
        end)
      {:error, error_message} ->
        {:error, "Unable to enqueue Job: #{error_message}"}
    end
  end

  @spec atomic_push(job, number) :: response
  defp atomic_push(job, at) when is_map(job) and is_number(at) and at > 1_000_000_000 do
    case Poison.encode(%{job | enqueued_at: current_unix_timestamp()}) do
      {:ok, encoded_job} ->
        :poolboy.transaction(:sidewalk_pool, fn(conn) ->
          with {:ok, _} <- Redix.command(conn, ["ZADD", namespacify("schedule"), to_string(at), encoded_job]), do: {:ok, job.jid}
        end)
      {:error, error_message} ->
        {:error, "Unable to enqueue delayed Job: #{error_message}"}
    end
  end

  @spec random_jid :: String.t
  defp random_jid do
    :crypto.strong_rand_bytes(12)
    |> Base.encode16(case: :lower)
  end

  @spec namespacify(String.t) :: String.t
  defp namespacify(key) do
    if namespace = Application.get_env(:sidewalk, :namespace) do
      "#{namespace}:#{key}"
    else
      key
    end
  end

  @spec current_unix_timestamp :: Float.t
  defp current_unix_timestamp do
    {mega_seconds, seconds, microseconds} = :os.timestamp
    String.to_float("#{mega_seconds}#{seconds}.#{microseconds}")
  end
end
