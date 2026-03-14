defmodule ChatMini.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :avatar_url, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :avatar_url])
    |> validate_required([:username, :email])
    |> validate_password()
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    password = get_change(changeset, :password)
    is_new = is_nil(changeset.data.id)

    if is_new or (password && password != "") do
      changeset
      |> validate_required([:password])
      |> validate_length(:password, min: 6)
      |> hash_password()
    else
      changeset
    end
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end
end
