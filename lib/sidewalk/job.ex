defmodule Sidewalk.Job do
  @moduledoc ~S"""
  This struct represents a typical Sidewalk job.

  ## Struct definitions

  - **jid**         -> A 24 character long job identifier
  - **class**       -> The worker class which is responsible for executing the job.
  - **args**        -> The arguments passed which should be passed to the worker.
  - **created_at**  -> The timestamp when the job is created by Sidewalk.
  - **enqueue_at**  -> The timestamp when the job is really enqueued with the Redis server.
  - **queue**       -> The queue where a job should be enqueued. Defaults to "default" queue.
  - **retry**       -> Tells the Sidekiq worker to retry the enqueue job.
  """

  @derive [Poison.Encoder]
  defstruct [
    jid: "",
    class: "",
    args: [],
    created_at: 0.0,
    enqueued_at: 0.0,
    queue: "default",
    retry: true
  ]

  @type t :: %Sidewalk.Job{
    jid: String.t,
    class: String.t,
    args: list(),
    created_at: float(),
    enqueued_at:  float(),
    queue: String.t,
    retry: boolean
  }
end
