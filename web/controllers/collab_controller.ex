defmodule Survey.CollabController do
  use Survey.Web, :controller
  alias Survey.DesignGroup
  alias Survey.Etherpad
  require Logger
  import Prelude

  @external_resource "data/templates/wk5.txt"
  @template File.read!("data/templates/wk5.txt")
  @wiki_disabled Application.get_env(:confluence, :disabled)

  def index(conn, _) do
    user = conn.assigns.user
    group = DesignGroup.get_by_user(user.id)

    if !group.design_group_id do
      ParamSession.redirect(conn, "/design_groups/select")
    else
      unless @wiki_disabled do
        ensure_wiki(user)
        user = conn.assigns.user
        group = DesignGroup.get_by_user(user.id)
        wiki_url = Survey.User.gen_wiki_url(user.id)
      else
        wiki_url = ""
      end
      members = DesignGroup.get_members(group.design_group_id)
      etherpad = Etherpad.ensure_etherpad(group.design_group_id)
      old_etherpads = Etherpad.past_etherpads(group.design_group_id)

      others = members
      |> Enum.filter(fn [x, _] -> x != user.id end)

      Mail.send_notification(group.design_group_id, user.nick,
        group.design_group.title, others)
      conn
      |> put_layout(false)
      |> render "index.html", user: user,
        group: group.design_group,
        etherpad: etherpad,
        old_etherpads: old_etherpads,
        members: members,
        wiki_url: wiki_url,
        template: @template,
        max_review: Survey.Review.max_review,
        admin: false
    end
  end

  def admin(conn, %{"id" => id}) do
    group = DesignGroup.get(string_to_int_safe(id))

    if !group.id do
      html conn, "Design group does not exist"
    else
      unless @wiki_disabled do
        wiki_url = group.wiki_url
      else
        wiki_url = ""
      end
      members = DesignGroup.get_members(group.id)
      etherpad = Etherpad.ensure_etherpad(group.id)
      old_etherpads = Etherpad.past_etherpads(group.id)

      others = members

      conn
      |> put_layout(false)
      |> render "index.html",
        user: %{nick: "Admin", id: 0},
        group: group,
        etherpad: etherpad,
        old_etherpads: old_etherpads,
        members: members,
        wiki_url: wiki_url,
        template: @template,
        max_review: Survey.Review.max_review,
        admin: true
    end

  end

  def leave(conn, _) do
    Logger.info("User left design group")
    %{ conn.assigns.user | design_group_id: nil } |> Repo.update!
    ParamSession.redirect(conn, "/design_groups/select")
  end

  def email(conn, params) do
    user = conn.assigns.user
    Mail.send_group_email(user.design_group_id, user.id, user.nick, params["subject"], params["content"])
    Logger.info("#{user.id} sent group mail")
    json conn, "success"
  end
  #--------------------------------------------------------------------------------

  def ensure_wiki(user) do
    if !(user.wiki_pwd) do
      Survey.Encore.add_user(user.id)
    end
    group = Survey.DesignGroup.get(user.design_group_id)
    if !(group.wiki_url) do
      Survey.Encore.add_group_page(group.id)
    end
  end
end

