defmodule Sidewalk.ActiveJob do
  @moduledoc """
  This struct represents a job that will be compatible with ActiveJob.
  """

  # https://github.com/rails/rails/blob/1e8c791ed29aed7791bba5893d2a4d6e00341998/activejob/lib/active_job/core.rb#L84-L96

  @derive [Poison.Encoder]
  defstruct [
    job_class: "",
    job_id: "",
    provider_job_id: "",
    queue_name: "default",
    priority:  "",
    arguments: [],
    executions: 0,
    locale: "en",
    enqueued_at: "",
    retry: true,
  ]

  @type t :: %Sidewalk.ActiveJob{
    job_class: String.t,
    job_id: String.t,
    provider_job_id: String.t,
    queue_name: String.t,
    priority: String.t,
    arguments: List.t,
    executions: pos_integer(),
    locale: String.t,
    enqueued_at: Float.t,
    retry: boolean
  }
end
