defmodule Survey.HTML.Survey do
  import MultiDef
  import Survey.HTML.GridSuggest

  def gen_survey(file, form) do
    parse(file)
    |> Enum.map(fn(x) -> gen_elements(x, form) end)
    |> IO.iodata_to_binary
    |> Phoenix.HTML.raw
  end

  mdef gen_elements do
    {:header, txt}, _                         -> ["<h3>", txt, "</h3>"]
    %{type: "text"} = h, form                 -> ["<label>", h.name, ": </label><input name='#{form}[#{h.number}]' type=text><br>"]
    %{type: "radio"} = h, form                -> multi(form, h, "radio")
    %{type: "multi"} = h, form                -> multi(form, h, "checkbox")
    %{type: "textbox"} = h, form              -> ["<label>", h.name, ": </label><br>", "<textarea name='#{form}[#{h.number}]'></textarea><p>"]
    %{type: "grid", choicerange: _} = h, form -> grid_select(form, h.name, h.number, h.rows, List.to_tuple(h.choicerange))
    %{type: "grid", choices: _} = h, form     -> grid_select(form, h.name, h.number, h.rows, h.choices)
  end

  def multi(form, h, type) do
    opts = h.options
    |> Enum.with_index
    |> Enum.map(
      fn {x, i} -> 
        case type do
          "checkbox" -> ["<input name='#{form}[#{h.number}.#{[?a + i]}]' value='true' type=checkbox><label>", x, ": </label><br>"]
          "radio" -> ["<input name='#{form}[#{h.number}]' value='#{[?a + i]}' type=radio><label>", x, ": </label><br>"]
        end
      end)

    ["<h4>", h.name, "</h4>", opts]
  end

  mdef unsafe do
    {:safe, x} -> x
    x -> x
  end

  #================================================================================ 

  def parse(file) do
    File.stream!(file)
    |> Stream.filter(&remove_blank_lines/1)
    |> Stream.map(&String.rstrip/1)
    |> Stream.map(&classify_line_types/1)
    |> concat_blocks
  end
  
  def remove_blank_lines(x), do: String.strip(x) != ""

  mdef classify_line_types do
    "#"<>rest     -> {:header, rest}
    " "<>rest     -> {:sub, rest}
    "\t"<>rest    -> {:sub, rest}
    "choices"     -> :choices
    "choicerange" -> :choicerange
    "rows"        -> :rows
    rest          -> [type, q] = String.split(rest, ",", parts: 2); {:question, type, String.strip(q)}
  end

  def concat_blocks(x) do
    Enum.reduce(x, {:wait, 1, []}, &concat_blocks_proc/2)
    |> elem(2)
    |> Enum.reverse
  end

  mdef concat_blocks_proc do
    :choicerange, {_, num, acc}               -> {:choicerange, num, acc}
    :rows, {_, num, acc}                      -> {:rows, num, acc}
    :choices, {_, num, acc}                   -> {:choices, num, acc}
    {:question, "multi", name}, {_, num, acc} -> {:options, num + 1, [ %{name: name, number: num, type: "multi"} | acc]}
    {:question, "radio", name}, {_, num, acc} -> {:options, num + 1, [ %{name: name, number: num, type: "radio"} | acc]}

    {:question, type, name}, {_, num, acc}    -> {:wait, num + 1, [ %{name: name, number: num, type: type} | acc]}
    {:header, _} = h, {_, num, acc}           -> {:wait, num, [h | acc]}

    {:sub, str}, {elem, num, [h | tl] }       -> { elem, num, [ append_in(h, elem, str) | tl ] }
  end

  def append_in(h, elem, str), do: Map.update(h, elem, [str], fn x -> List.insert_at(x, 999, str) end)
end