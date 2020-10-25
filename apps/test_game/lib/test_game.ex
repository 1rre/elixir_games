defmodule TestGame do
@behaviour :wx_object
@title "Test Game"
@size {600, 600}


  def start_link() do
    :wx_object.start_link(__MODULE__, [], [])
  end

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
    IO.puts("Resize")
    :wxPanel.setSize(panel, size)
    {:noreply, state}
  end
  def handle_event({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    {:stop, :normal, state}
  end
  def handle_event({:wx, _, _, _, {:wxKey, :key_down, _, _, kc, _, _, _, _, _, _, _, _}}, state = %{panel: panel, grid: grid}) do
    {:noreply, Map.put(state, :grid, case kc do
      83 -> move_rects(grid, :down)  |> draw_rects(panel)
      65 -> move_rects(grid, :left)  |> draw_rects(panel)
      87 -> move_rects(grid, :up)    |> draw_rects(panel)
      68 -> move_rects(grid, :right) |> draw_rects(panel)
      _ -> grid
    end)}
  end

  def add_block(grid\\List.duplicate(0, 16)) do
    new_grid = List.replace_at(grid, Enum.filter(0..15, &Enum.at(grid, &1) == 0) |> Enum.random(), 2)
    if Enum.any?(new_grid, &(&1 == 0)), do: new_grid, else: List.duplicate(0, 16) |> add_block()
  end

  def move_rects(grid, :down) do
    add_block(grid)
  end
  def move_rects(grid, :up) do
    add_block(grid)
  end
  def move_rects(grid, :left) do
    add_block(grid)
  end
  def move_rects(grid, :right) do
    Enum.reduce(15..0, grid, fn x, grid ->
      grid
    end) |> add_block()
  end

  def draw_rects(grid, panel) do
    brush = :wxBrush.new
    :wxBrush.setColour(brush, {200, 200, 200, 255})
    dc = :wxPaintDC.new(panel)
    :wxDC.setBackground(dc, brush)
    :wxDC.clear(dc)
    :wxBrush.setColour(brush, {255, 0, 255, 255})
    :wxPaintDC.setBrush(dc, brush)
    Enum.each(0..15, &(if Enum.at(grid, &1) != 0, do: :wxPaintDC.drawRectangle(dc, {(1 + div(&1, 4)) * 100, (1 + rem(&1, 4)) * 100, 100, 100})))
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
    {:wx_ref, _, _, pid} = TestGame.start_link
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end
  end
end

Script.main(System.argv)
