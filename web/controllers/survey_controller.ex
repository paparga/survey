defmodule Survey.SurveyController do
  use Survey.Web, :controller
  require Logger
  require Ecto.Query
  import Ecto.Query
  alias Survey.Repo
  alias Survey.User
  import Prelude

  plug :action

  def index(conn, _) do
    if conn.assigns.user.surveystate == 99 do
      render conn, "survey_success.html", message: "Thank you for completing the survey! We look forward to your ideas and creativity during the rest of the course."
    else
      render conn, "index.html"
    end
  end

  def submit(conn, params) do
    set_survey(conn, params, true)
    render conn, "survey_success.html", message: "Thank you for completing the survey! We look forward to your ideas and creativity during the rest of the course."
  end

  def submitajax(conn, params) do
    set_survey(conn, params)
    text conn, "Success"
  end

  def exit(conn, _) do
    if conn.assigns.user.exitsurvey_state do
      render conn, "survey_success.html", message: "Thank you for completing the survey, and for taking part in this course. Best of luck in integrating ideas and inspiration from this course in your future endeavours!"
    else
      render conn, "exit.html"
    end
  end

  def submit_exit(conn, params) do
    set_survey_exit(conn, params, true)
    render conn, "survey_success.html", message: "Thank you for completing the survey, and for taking part in this course. Best of luck in integrating ideas and inspiration from this course in your future endeavours!"
  end

  def submitajax_exit(conn, params) do
    set_survey_exit(conn, params)
    text conn, "Success"
  end

  defp set_survey_exit(conn, params, complete \\ false) do
    Logger.info("Saving to database")

    user = conn.assigns.user
    user = %{user | exitsurvey: clean_survey(params["f"]) }
    if complete do
      user = %{user | exitsurvey_state: true }
    end
    Repo.update!(user)
  end

  defp set_survey(conn, params, complete \\ false) do
    Logger.info("Saving to database")

    user = conn.assigns.user
    user = %{user | survey: clean_survey(params["f"]) }
    if complete do
      user = %{user | surveystate: 99 }
    end
    Repo.update!(user)
  end

  defp clean_survey(survey) do
    survey
    |> proc_params
    |> Enum.filter(&not_empty/1)
    |> Enum.map(&integers/1)
    |> Enum.into(%{})
  end

  defp not_empty({_, ""}), do: false
  defp not_empty(_), do: true

  defp integers({"#" <> k, val}), do: {k, string_to_int_safe(val)}
  defp integers(x), do: x
end
