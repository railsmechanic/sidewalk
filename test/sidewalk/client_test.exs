defmodule Sidewalk.ClientTest do
  use ExUnit.Case

  alias Sidewalk.{ActiveJob, Client, Job}

  setup do
    {:ok, conn} = Redix.start_link
    {:ok, "OK"} = Redix.command(conn, ~w(FLUSHDB))
    {:ok, [redis: conn]}
  end

  describe "enqueue functions with invalid parameters" do
    test "enqueue/1 with invalid parameters" do
      assert {:error, _} = Client.enqueue("foo")
      assert {:error, _} = Client.enqueue(1)
      assert {:error, _} = Client.enqueue(%{})
      assert {:error, _} = Client.enqueue(%Job{})
      assert {:error, _} = Client.enqueue(%Job{class: ""})
      assert {:error, _} = Client.enqueue(%Job{class: 1})
      assert {:error, _} = Client.enqueue(%Job{class: "MyWorker", args: ""})
      assert {:error, _} = Client.enqueue(%Job{class: "MyWorker", args: 1})
      assert {:error, _} = Client.enqueue(%Job{class: "MyWorker", args: [], queue: 1})
      assert {:error, _} = Client.enqueue(%Job{class: "MyWorker", args: [1,2,3], queue: ""})
      assert {:error, _} = Client.enqueue(%ActiveJob{})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: ""})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: 1})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: ""})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: 1})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: [], queue_name: 1})
      assert {:error, _} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: ""})
    end

    test "enqueue_in/2 with invalid parameters" do
      assert {:error, _} = Client.enqueue_in("foo")
      assert {:error, _} = Client.enqueue_in(1)
      assert {:error, _} = Client.enqueue_in(%{})
      assert {:error, _} = Client.enqueue_in(%Job{})
      assert {:error, _} = Client.enqueue_in(%Job{class: ""})
      assert {:error, _} = Client.enqueue_in(%Job{class: 1})
      assert {:error, _} = Client.enqueue_in(%Job{class: "MyWorker", args: ""})
      assert {:error, _} = Client.enqueue_in(%Job{class: "MyWorker", args: 1})
      assert {:error, _} = Client.enqueue_in(%Job{class: "MyWorker", args: [], queue: 1})
      assert {:error, _} = Client.enqueue_in(%Job{class: "MyWorker", args: [1,2,3], queue: ""})
      assert {:error, _} = Client.enqueue_in(%Job{class: "MyWorker", args: [1,2,3], queue: "default"}, "")
      assert {:error, _} = Client.enqueue_in(%ActiveJob{})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: ""})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: 1})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: ""})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: 1})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: [], queue_name: 1})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: ""})
      assert {:error, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: "default"}, "")
    end

    test "enqueue_at/2 with invalid parameters" do
      assert {:error, _} = Client.enqueue_at("foo")
      assert {:error, _} = Client.enqueue_at(1)
      assert {:error, _} = Client.enqueue_at(%{})
      assert {:error, _} = Client.enqueue_at(%Job{})
      assert {:error, _} = Client.enqueue_at(%Job{class: ""})
      assert {:error, _} = Client.enqueue_at(%Job{class: 1})
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: ""})
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: 1})
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [], queue: 1})
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [1,2,3], queue: ""})
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [1,2,3], queue: "default"}, "")
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [1,2,3], queue: "default"}, 1)
      assert {:error, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [1,2,3], queue: "default"}, 1)
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: ""})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: 1})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: ""})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: 1})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [], queue_name: 1})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: ""})
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: "default"}, "")
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: "default"}, 1)
      assert {:error, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], queue_name: "default"}, 1)
    end
  end

  describe "enqueue functions with valid parameters for a successful enqueuing" do
    test "enqueue/1 with valid Job parameters" do
      {:ok, jid} = Client.enqueue(%Job{class: "MyWorker", args: [1,2,3]})
      assert is_binary(jid)
      assert String.length(jid) == 24
    end

    test "enqueue/1 with valid ActiveJob parameters" do
      {:ok, jid} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: [1, 2, 3]})

      assert is_binary(jid)
      assert String.length(jid) == 24
    end

    test "enqueue_in/2 with valid Job parameters" do
      {:ok, jid} = Client.enqueue_in(%Job{class: "MyWorker", args: [1,2,3]}, 120)
      assert is_binary(jid)
      assert String.length(jid) == 24
    end

    test "enqueue_in/2 with valid ActiveJob parameters" do
      {:ok, jid} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3]}, 120)
      assert is_binary(jid)
      assert String.length(jid) == 24
    end

    test "enqueue_at/2 with valid Job parameters" do
      {:ok, jid} = Sidewalk.Client.enqueue_at(%Sidewalk.Job{class: "MyWorker", args: [1,2,3]}, 1_900_000_000)
      assert is_binary(jid)
      assert String.length(jid) == 24
    end

    test "enqueue_at/2 with valid ActiveJob parameters" do
      {:ok, jid} = Sidewalk.Client.enqueue_at(%Sidewalk.ActiveJob{job_class: "MyWorker", arguments: [1,2,3]}, 1_900_000_000)
      assert is_binary(jid)
      assert String.length(jid) == 24
    end
  end

  describe "successful write to redis for Jobs" do
    test "enqueue/1 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue(%Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"})
      assert Redix.command!(redis, ~w(SISMEMBER queues foo)) == 1
      stored_job = Redix.command!(redis, ~w(LPOP queue:foo))
      |> Poison.decode!(as: %Job{})

      assert is_binary(stored_job.jid)
      assert String.length(stored_job.jid) == 24
      assert stored_job.class == "MyWorker"
      assert length(stored_job.args) == 3
      assert stored_job.args == [1,2,3]
      assert stored_job.queue == "foo"
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at
    end

    test "enqueue_in/2 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue_in(%Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"}, 60)
      [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))
      stored_job = Poison.decode!(raw_stored_job, as: %Job{})
      assert is_binary(stored_job.jid)
      assert String.length(stored_job.jid) == 24
      assert stored_job.class == "MyWorker"
      assert length(stored_job.args) == 3
      assert stored_job.args == [1,2,3]
      assert stored_job.queue == "foo"
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at
      assert String.to_float(raw_execution_time) > 1_000_000_000
    end

    test "enqueue_at/2 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue_at(%Job{class: "MyWorker", args: [1,2,3], retry: false, queue: "foo"}, 2_000_000_000)
      [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))
      stored_job = Poison.decode!(raw_stored_job, as: %Job{})
      assert is_binary(stored_job.jid)
      assert String.length(stored_job.jid) == 24
      assert stored_job.class == "MyWorker"
      assert length(stored_job.args) == 3
      assert stored_job.args == [1,2,3]
      assert stored_job.queue == "foo"
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at
      assert String.to_integer(raw_execution_time) == 2_000_000_000
    end
  end

  describe "successful write to redis for ActiveJobs" do
    test "enqueue/1 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], retry: false, queue_name: "foo"})

      assert Redix.command!(redis, ~w(SISMEMBER queues foo)) == 1

      stored_job = Redix.command!(redis, ~w(LPOP queue:foo))
      |> Poison.decode!(as: %Job{})

      %{jid: stored_jid, queue: stored_queue_name} = stored_job

      assert is_binary(stored_jid)
      assert String.length(stored_jid) == 24
      assert stored_queue_name == "foo"
      assert stored_job.class == "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
      assert stored_job.wrapped == "MyWorker"
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0

      [active_job] = stored_job.args

      assert active_job["arguments"] == [1, 2, 3]
      assert active_job["job_class"] == "MyWorker"
      assert active_job["job_id"] == stored_jid
      assert active_job["queue_name"] == stored_queue_name
      assert active_job["retry"] == false
    end

    test "enqueue_in/2 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue_in(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], retry: false, queue_name: "foo"}, 60)

      [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))

      assert String.to_float(raw_execution_time) > 1_000_000_000

      stored_job = Poison.decode!(raw_stored_job, as: %Job{})

      %{jid: stored_jid, queue: stored_queue_name} = stored_job

      assert is_binary(stored_jid)
      assert String.length(stored_jid) == 24
      assert stored_queue_name == "foo"
      assert stored_job.class == "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
      assert stored_job.wrapped == "MyWorker"
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at

      [active_job] = stored_job.args

      assert active_job["arguments"] == [1, 2, 3]
      assert active_job["job_class"] == "MyWorker"
      assert active_job["job_id"] == stored_jid
      assert active_job["queue_name"] == stored_queue_name
      assert active_job["retry"] == false
    end

    test "enqueue_at/2 to write data correctly to redis", %{redis: redis} do
      assert {:ok, _} = Client.enqueue_at(%ActiveJob{job_class: "MyWorker", arguments: [1,2,3], retry: false, queue_name: "foo"}, 2_000_000_000)

      [raw_stored_job, raw_execution_time] = Redix.command!(redis, ~w(ZRANGE schedule 0 0 WITHSCORES))

      assert String.to_integer(raw_execution_time) == 2_000_000_000

      stored_job = Poison.decode!(raw_stored_job, as: %Job{})

      %{jid: stored_jid, queue: stored_queue_name} = stored_job

      assert is_binary(stored_jid)
      assert String.length(stored_jid) == 24
      assert stored_queue_name == "foo"
      assert stored_job.class == "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
      assert stored_job.wrapped == "MyWorker"
      assert stored_job.retry == false
      assert stored_job.enqueued_at > 0
      assert stored_job.created_at > 0
      assert stored_job.created_at < stored_job.enqueued_at

      [active_job] = stored_job.args

      assert active_job["arguments"] == [1, 2, 3]
      assert active_job["job_class"] == "MyWorker"
      assert active_job["job_id"] == stored_jid
      assert active_job["queue_name"] == stored_queue_name
      assert active_job["retry"] == false
    end
  end
end
