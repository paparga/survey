defmodule EnsureLti do
  @moduledoc """
  Checks if LTI_id exists in session hash, otherwise runs LTI verification.
  """

  use Behaviour
  @behaviour Plug
  import Plug.Conn

  require Logger

  def init([]), do: []

  def call(conn, _) do
    conn = fetch_session(conn)
    if conn.params["oauth_signature"] || !get_session(conn, :lti_userid) do
      PlugLti.call(conn, [])
      |> put_session(:lti_userid, conn.params["user_id"])
    else
      conn
    end
  end
end