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
    grid = [
      [2, 0, 0, 0],
      [0, 0, 2, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0]
    ]

    state = %{panel: panel, grid: grid}
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
    Map.put_new(state, :grid, case kc do
      83 -> move_rects(grid, :down)  |> draw_rects(panel)
      65 -> move_rects(grid, :left)  |> draw_rects(panel)
      87 -> move_rects(grid, :up)    |> draw_rects(panel)
      68 -> move_rects(grid, :right) |> draw_rects(panel)
      _ -> grid
    end)
    {:noreply, state}
  end

  def move_rects(grid, :down) do
    grid
  end
  def move_rects(grid, :up) do
    grid
  end
  def move_rects(grid, :left) do
    grid
  end
  def move_rects(grid, :right) do
    grid
  end

  def draw_rects(grid, panel) do
    brush = :wxBrush.new
    :wxBrush.setColour(brush, {200, 200, 200, 255})
    dc = :wxPaintDC.new(panel)
    :wxDC.setBackground(dc, brush)
    :wxDC.clear(dc)
    :wxBrush.setColour(brush, {255, 0, 255, 255})
    :wxPaintDC.setBrush(dc, brush)
    Enum.each(0..3, fn x ->
      Enum.each(0..3, fn y ->
        if Enum.at(Enum.at(grid, x), y) != 0, do: :wxPaintDC.drawRectangle(dc, {(1 + x) * 100, (1 + y) * 100, 100, 100})
      end)
    end)
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
