defmodule EnsureRegistered do
  @moduledoc """
  A plug run before every regular page request, to ensure that the user is registered with our system.
  If not, user is redirected to our registration page, and after successful registration, is redirected
  back to the original target.

  Initially checks whether user_id is stored in the cookie, if not, looks up user in database.
  """

  use Behaviour
  @behaviour Plug
  import Plug.Conn

  require Ecto.Query
  import Ecto.Query
  require Logger

  defmodule NoIDProvided, do:
    defexception message: "no ID provided"

  defmodule UserNotInDB, do:
    defexception message: "provided user id not found in database"

  def init([]), do: []

  def call(conn, _) do
    try do
      userid = get_session(conn, :repo_userid)
      if !userid do
        hash = conn.params["user_id"] || get_session(conn, :lti_userid)
        if !hash, do: raise NoIDProvided

        query = from u in Survey.User, where: u.hash == ^hash, select: u.id
        userid = Survey.Repo.one(query)
        if !userid, do: raise UserNotInDB
        conn = put_session(conn, :repo_userid, userid)
      end

      Logger.info("Verified user id #{inspect(userid)}")
      conn

    rescue 
      e in NoIDProvided -> 
        Logger.info "EnsureRegistered: " <> Exception.message(e)
        conn
          |> put_resp_header("content-type", "text/plain; charset=utf-8")
          |> send_resp(Plug.Conn.Status.code(:forbidden), 
            "User not registered")
          |> halt
      UserNotInDB -> register_user(conn)

      e -> raise e
    end
  end

  def register_user(conn) do
    conn 
    |> put_private(:ensure_registered_redirect, full_path(conn))
    |> put_resp_header("location", "/register")
    |> send_resp(302, "")
    |> halt
  end
end