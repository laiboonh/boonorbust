Mox.defmock(HttpBehaviourMock, for: Boonorbust.HttpBehaviour)
Application.put_env(:boonorbust, :http, HttpBehaviourMock)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Boonorbust.Repo, :manual)
