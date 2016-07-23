# Sidewalk
Sidewalk is an Elixir client for the simple, »efficient background processing library for Ruby«.
It can be used to enqueue jobs for later processing alongside e.g. with an already existing Ruby application.
For more information about Sidekiq please refer to http://sidekiq.org.

To use Sidewalk you need to create a `%Sidewalk.Job{}` and enqueue it with one of the enqueue functions.

## Supported features
* Redis namespaces as already known with Sidekiq
* Ability to configure the Redis server connection details
* Ability to configuration a Redis pool size
* Enqueuing jobs to be executed immediately
* Enqueuing jobs to be executed in X seconds
* Enqueuing jobs to be executed at a specific time

## Installation
1. Add `sidewalk` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:sidewalk, "~> 0.2.0"}]
  end
  ```

2. Ensure `sidewalk` is started before your application:

  ```elixir
  def application do
    [applications: [:sidewalk]]
  end
  ```

3. Fetch dependencies

  ```bash
  mix deps.get
  ```

## Configuration example

```elixir
config :sidewalk,
  host: "localhost",
  port: 6379,
  password: "you password",
  namespace: "your_namespace",
  database: 0,
  pool_size: 10
```

## Usage
Sidewalk offers three modes for enqueuing jobs:

### 1. Enqueuing a job with an immediate execution

```elixir
job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
{:ok, "2f87a952ced00ea6cdd61245"} = Sidewalk.Client.enqueue(job)
```

### 2. Enqueuing a job with a delayed execution defined in seconds

```elixir
# The time when the job should be executed is defined in seconds

job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
{:ok, "a805893e8bd98bf965d1dd54"} = Sidewalk.Client.enqueue_in(job, 120)
```

### 3. Enqueuing a job to be executed at a specific time

```elixir
# The time when the job should be executed is defined as a unix timestamp

job = %Sidewalk.Job{class: "MyWorker", args: ['bob', 1, %{foo: 'bar'}]}
{:ok, "d6ceac7d6c42d35ff6cac8a0"} = Sidewalk.Client.enqueue_at(job, 1546293600)
```

## License
See See [LICENSE](https://raw.githubusercontent.com/railsmechanic/sidewalk/master/LICENSE).
