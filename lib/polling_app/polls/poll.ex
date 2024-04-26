defmodule PollingApp.Polls.Poll do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:title, :string)
    field(:option1, :string)
    field(:option2, :string)
    field(:votes, :integer, default: 0)
    timestamps()
  end

  @doc false
  def changeset(poll, attrs) do
    poll
    |> cast(attrs, [:id, :title, :option1, :option2])
    |> validate_required([:title, :option1, :option2])
  end
end
