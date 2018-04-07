defmodule Sidewalk.ClientTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = Redix.start_link
    {:ok, "OK"} = Redix.command(conn, ~w(FLUSHDB))
    {:ok, [redis: conn]}
  end

  ## --> Test enqueue functions with invalid parameters
  test "enqueue/1 with invalid parameters" do
    assert {:error, _} = Sidewalk.Client.enqueue("foo")
    assert {:error, _} = Sidewalk.Client.enqueue(1)
    assert {:error, _} = Sidewalk.Client.enqueue(%{})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: ""})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: 1})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: ""})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: 1})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: [], queue: 1})
    assert {:error, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: ""})
  end

  test "enqueue_in/2 with invalid parameters" do
    assert {:error, _} = Sidewalk.Client.enqueue_in("foo")
    assert {:error, _} = Sidewalk.Client.enqueue_in(1)
    assert {:error, _} = Sidewalk.Client.enqueue_in(%{})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: [], queue: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: "default"}, "")
  end

  test "enqueue_at/2 with invalid parameters" do
    assert {:error, _} = Sidewalk.Client.enqueue_at("foo")
    assert {:error, _} = Sidewalk.Client.enqueue_at(1)
    assert {:error, _} = Sidewalk.Client.enqueue_at(%{})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [], queue: 1})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: ""})
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: "default"}, "")
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: "default"}, 1)
    assert {:error, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], queue: "default"}, 1)
  end

  ## --> Test enqueue functions with valid parameters for a successfull enqueuing
  test "enqueue/1 with valid parameters" do
    {:ok, jid} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: [1,2,3]})
    assert is_binary(jid)
    assert String.length(jid) == 24
  end

  test "enqueue_in/2 with valid parameters" do
    {:ok, jid} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: [1,2,3]}, 120)
    assert is_binary(jid)
    assert String.length(jid) == 24
  end

  test "enqueue_at/2 with valid parameters" do
    {:ok, jid} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3]}, 1_900_000_000)
    assert is_binary(jid)
    assert String.length(jid) == 24
  end

  ## --> Test successfull write to redis
  test "enqueue/1 to write data correctly to redis", %{redis: redis} do
    assert {:ok, _} = Sidewalk.Client.enqueue(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"})
    assert Redix.command!(redis, ~w(SISMEMBER queues foo)) == 1
    stored_job = Redix.command!(redis, ~w(LPOP queue:foo))
    |> Poison.decode!(as: %Sidewalk.Job{})

    assert is_binary(stored_job.jid)
    assert String.length(stored_job.jid) == 24
    assert stored_job.class == "MyWorker"
    assert length(stored_job.args) == 3
    assert stored_job.args == [1,2,3]
    assert stored_job.queue == "foo"
    assert stored_job.retry == false
    assert stored_job.enqueued_at > 0
    assert stored_job.created_at > 0
    assert stored_job.created_at <= stored_job.enqueued_at
  end

  test "enqueue_in/2 to write data correctly to redis", %{redis: redis} do
    assert {:ok, _} = Sidewalk.Client.enqueue_in(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"}, 60)
    [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))
    stored_job = Poison.decode!(raw_stored_job, as: %Sidewalk.Job{})
    assert is_binary(stored_job.jid)
    assert String.length(stored_job.jid) == 24
    assert stored_job.class == "MyWorker"
    assert length(stored_job.args) == 3
    assert stored_job.args == [1,2,3]
    assert stored_job.queue == "foo"
    assert stored_job.retry == false
    assert stored_job.enqueued_at > 0
    assert stored_job.created_at > 0
    assert stored_job.created_at <= stored_job.enqueued_at
    assert String.to_float(raw_execution_time) > 1_000_000_000
  end

  test "enqueue_at/2 to write data correctly to redis", %{redis: redis} do
    assert {:ok, _} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"}, 2_000_000_000)
    [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))
    stored_job = Poison.decode!(raw_stored_job, as: %Sidewalk.Job{})
    assert is_binary(stored_job.jid)
    assert String.length(stored_job.jid) == 24
    assert stored_job.class == "MyWorker"
    assert length(stored_job.args) == 3
    assert stored_job.args == [1,2,3]
    assert stored_job.queue == "foo"
    assert stored_job.retry == false
    assert stored_job.enqueued_at > 0
    assert stored_job.created_at > 0
    assert stored_job.created_at <= stored_job.enqueued_at
    assert String.to_integer(raw_execution_time) == 2_000_000_000
  end

end
