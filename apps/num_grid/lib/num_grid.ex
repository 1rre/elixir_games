defmodule Games.NumGrid do
@behaviour :wx_object
@title "2048"
@size {600, 600}


  def start_link(), do: :wx_object.start_link(__MODULE__, [], [])

  def init(_args \\ []) do
    wx = :wx.new
    frame = :wxFrame.new(wx, -1, @title, size: @size)
    :wxFrame.connect(frame, :size)
    :wxFrame.connect(frame, :close_window)

    panel = :wxPanel.new(frame, [])
    :wxPanel.connect(panel, :paint, [:callback])
    :wxPanel.connect(panel, :key_down)

    :wxFrame.show(frame)
    state = %{panel: panel, grid: add_block()}
    {frame, state}
  end

  def handle_event({:wx, _, _, _, {:wxSize, :size, size, _}}, state = %{panel: panel}) do
    :wxPanel.setSize(panel, size)
    {:noreply, state}
  end
  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state), do: {:stop, :normal, state}
  def handle_event({:wx, _, _, _, {:wxKey, :key_down, _, _, kc, _, _, _, _, _, _, _, _}}, state = %{panel: panel, grid: grid}), do:
    {:noreply, Map.put(state, :grid, case kc do
      317 -> take_turn(grid, :down)  |> draw_rects(panel)
      83  -> take_turn(grid, :down)  |> draw_rects(panel)
      314 -> take_turn(grid, :left)  |> draw_rects(panel)
      65  -> take_turn(grid, :left)  |> draw_rects(panel)
      315 -> take_turn(grid, :up)    |> draw_rects(panel)
      87  -> take_turn(grid, :up)    |> draw_rects(panel)
      316 -> take_turn(grid, :right) |> draw_rects(panel)
      68  -> take_turn(grid, :right) |> draw_rects(panel)
      _ -> IO.puts(kc)
        grid
    end)}

  def add_block(grid\\List.duplicate(0, 16)) do
    new_grid = List.replace_at(grid, Enum.filter(0..15, &Enum.at(grid, &1) == 0) |> Enum.random(), 2)
    if Enum.any?(new_grid, &(&1 == 0)), do: new_grid, else: List.duplicate(0, 16) |> add_block()
  end

  def take_turn(grid, dir), do:
    move_rects(grid, dir)
    |> merge_rects(dir)
    |> move_rects(dir)
    |> add_block()

  def move_rects(grid, direction)
  def move_rects(grid, :down), do: (
    Enum.reduce(0..3, grid, fn x, grid ->
      Enum.reduce(0..2, grid, fn y, grid ->
        if Enum.at(grid, x + 4 * y) != 0 && Enum.at(grid, x + 4 * (y + 1)) == 0 do
          List.replace_at(grid, x + 4 * (y + 1), Enum.at(grid, x + 4 * y))
          |> List.replace_at(x + 4 * y, 0)
        else
          grid
        end
      end)
    end)
    |> case do
     ^grid -> grid
      grid -> move_rects(grid, :down)
    end
  )
  def move_rects(grid, :up), do: (
    Enum.reduce(3..0, grid, fn x, grid ->
      Enum.reduce(3..1, grid, fn y, grid ->
        if Enum.at(grid, x - 4 * y) != 0 && Enum.at(grid, x - 4 * (y + 1)) == 0 do
          List.replace_at(grid, x - 4 * (y + 1), Enum.at(grid, x - 4 * y))
          |> List.replace_at(x - 4 * y, 0)
        else
          grid
        end
      end)
    end)
    |> case do
     ^grid -> grid
      grid -> move_rects(grid, :up)
    end
  )
  def move_rects(grid, :left), do: (
    Enum.reduce(0..3, grid, fn x, grid ->
      Enum.reduce(1..3, grid, fn y, grid ->
        if Enum.at(grid, 4 * x - y) != 0 && Enum.at(grid, 4 * x - (y + 1)) == 0 do
          List.replace_at(grid, 4 * x - (y + 1), Enum.at(grid, 4 * x - y))
          |> List.replace_at(4 * x - y, 0)
        else
          grid
        end
      end)
    end)
    |> case do
     ^grid -> grid
      grid -> move_rects(grid, :left)
    end
  )
  def move_rects(grid, :right), do: (
    Enum.reduce(3..0, grid, fn x, grid ->
      Enum.reduce(0..2, grid, fn y, grid ->
        if Enum.at(grid, 4 * x + y) != 0 && Enum.at(grid, 4 * x + (y + 1)) == 0 do
          List.replace_at(grid, 4 * x + (y + 1), Enum.at(grid, 4 * x + y))
          |> List.replace_at(4 * x + y, 0)
        else
          grid
        end
      end)
    end)
    |> case do
     ^grid -> grid
      grid -> move_rects(grid, :right)
    end
  )
  def merge_rects(grid, :down), do: (
    Enum.reduce(3..0, grid, fn x, grid ->
      Enum.reduce(2..0, grid, fn y, grid ->
        if Enum.at(grid, x + 4 * y) == Enum.at(grid, x + 4 * (y + 1)) do
          List.replace_at(grid, x + 4 * (y + 1), Enum.at(grid, x + 4 * (y + 1)) * 2)
          |> List.replace_at(x + 4 * y, 0)
        else
          grid
        end
      end)
    end)
  )
  def merge_rects(grid, :up), do: (
    Enum.reduce(3..0, grid, fn x, grid ->
      Enum.reduce(3..1, grid, fn y, grid ->
        if Enum.at(grid, x - 4 * y) == Enum.at(grid, x - 4 * (y + 1)) do
          List.replace_at(grid, x - 4 * (y + 1), Enum.at(grid, x - 4 * (y + 1)) * 2)
          |> List.replace_at(x - 4 * y, 0)
        else
          grid
        end
      end)
    end)
  )
  def merge_rects(grid, :left), do: (
    Enum.reduce(0..3, grid, fn x, grid ->
      Enum.reduce(3..1, grid, fn y, grid ->
        if Enum.at(grid, 4 * x - y) == Enum.at(grid, 4 * x - (y + 1)) do
          List.replace_at(grid, 4 * x - (y + 1), Enum.at(grid, 4 * x - (y + 1)) * 2)
          |> List.replace_at(4 * x - y, 0)
        else
          grid
        end
      end)
    end)
  )
  def merge_rects(grid, :right), do: (
    Enum.reduce(3..0, grid, fn x, grid ->
      Enum.reduce(2..0, grid, fn y, grid ->
        if Enum.at(grid, 4 * x + y) == Enum.at(grid, 4 * x + (y + 1)) do
          List.replace_at(grid, 4 * x + (y + 1), Enum.at(grid, 4 * x + (y + 1)) * 2)
          |> List.replace_at(4 * x + y, 0)
        else
          grid
        end
      end)
    end)
  )
  def draw_rects(grid, panel) do
    brush = :wxBrush.new
    :wxBrush.setColour(brush, {200, 200, 200, 255})
    dc = :wxPaintDC.new(panel)
    :wxDC.setBackground(dc, brush)
    :wxDC.clear(dc)
    :wxDC.drawRectangle(dc, {100, 100, 400, 400})
    :wxBrush.setColour(brush, {255, 0, 255, 255})
    :wxPaintDC.setBrush(dc, brush)
    #font = :wxFont.new()
    #:wxFont.setWeight(font, 10)
    #:wxPaintDC.setFont(dc, font)
    Enum.each(0..15, &(if Enum.at(grid, &1) != 0 do
      :wxPaintDC.drawRectangle(dc, {(1 + rem(&1, 4)) * 100, (1 + div(&1, 4)) * 100, 100, 100})
      :wxPaintDC.drawText(dc, "#{Enum.at(grid, &1)}", {(1 + rem(&1, 4)) * 100 + 45, (1 + div(&1, 4)) * 100 + 35})
    end))
    grid
  end

  def handle_sync_event({:wx, _, _, _, {:wxPaint, :paint}}, _, %{panel: panel, grid: grid}) do
    brush = :wxBrush.new
    :wxBrush.setColour(brush, {200, 200, 200, 255})
    dc = :wxPaintDC.new(panel)
    :wxDC.setBackground(dc, brush)
    :wxDC.clear(dc)
    draw_rects(grid, panel)
    :ok
  end

end

defmodule Script do
  def main(_args) do
    {:wx_ref, _, _, pid} = Games.NumGrid.start_link
    ref = Process.monitor(pid)
    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end
  end
end
