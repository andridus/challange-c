defmodule Cumbuca.Schema do
  @moduledoc """
    Cumbuca Schema
  """
  defmacro __using__(_) do
    quote do
      use Bee.Schema,
        foreign_key_type: :binary_id,
        primary_key: {:id, :binary_id, autogenerate: true},
        timestamp_opts: [type: :utc_datetime]

      use Ecto.Schema

      @timestamps_opts [type: :utc_datetime]
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      import Ecto.Changeset
      import Cumbuca.Schema

      def _swagger_schema_(permission \\ :admin) do
        [title, description] = String.splitter(@moduledoc, ["\n", "---\n"]) |> Enum.take(2)

        description =
          "fields available for `#{String.upcase(to_string(permission))}` permission\n #{description}"

        available_fields = bee_permission(permission)

        {properties, required, example} =
          bee_raw_fields()
          |> Enum.reduce({%{}, [], %{}}, fn {field, opts}, {props, reqs, exampls} = acc ->
            is_hidden = get_in_(opts, [:__swagger__, :hidden], false)

            if is_nil(opts[:virtual]) && !is_hidden && field in available_fields do
              type = opts[:type]
              field = get_in_(opts, [:__swagger__, :field], field)

              type =
                get_in_(
                  opts,
                  [:__swagger__, :type],
                  if(type == :relation_type, do: :uuid, else: type)
                )

              enum = get_in_(opts, [:values])

              example =
                get_in_(
                  opts,
                  [:__swagger__, :example],
                  if(type == :relation_type, do: Ecto.UUID.generate())
                )

              data =
                %PhoenixSwagger.Schema{
                  description: get_in_(opts, [:__swagger__, :description]),
                  type: type,
                  default: get_in_(opts, [:default])
                }
                |> put_in_(:enum, enum)
                |> put_in_(:example, example)

              props = Map.put(props, field, data)

              requireds =
                if opts[:required] do
                  [field | reqs]
                else
                  reqs
                end

              example = Map.put(exampls, field, data.example)
              {props, requireds, example}
            else
              acc
            end
          end)

        %PhoenixSwagger.Schema{
          description: String.trim(description),
          title: String.trim(title),
          type: "object",
          example: example,
          properties: properties,
          required: required
        }
      end
    end
  end

  def get_in_(opts, keys, default \\ nil) do
    get_in(opts, keys) || default
  rescue
    _ -> default
  end

  def put_in_(map, _key, nil), do: map

  def put_in_(map, key, value) do
    Map.put(map, key, value)
  end

  def associated_schema(%schema{}, assoc), do: associated_schema(schema, assoc)

  def associated_schema(schema, assoc) do
    schema.__schema__(:association, assoc)
    |> case do
      %{related: assoc_schema} -> assoc_schema
      _ -> {:error, :inexistent_association}
    end
  end

  @doc """
    Reload a entity
  """
  def reload(%schema{id: id}, opts \\ []),
    do: Module.concat([schema, Api]).get(id, opts)
end
