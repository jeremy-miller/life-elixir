defmodule CellTest do
  use ExUnit.Case, async: true
  import Enum, only: [member?: 2]
  doctest Cell

  test "start_link/1 starts a cell process with name `process` and registers it in the Registry" do
    position = {1, 0}
    {:ok, pid} = Cell.start_link(position)
    assert Registry.lookup(Cell.Registry, position) == [{pid, nil}]
    Supervisor.terminate_child(Cell.Supervisor, pid)
  end

  test "create/1 creates a new cell a `position` in the Supervisor" do
    position = {1, 2}
    {:ok, pid} = Cell.create(position)
    # there may be more children in the Cell.Supervisor since these tests
    # are running asynchronously, so just check if our `pid` is one of them.
    assert member?(Supervisor.which_children(Cell.Supervisor), {:undefined, pid, :worker, [Cell]})
    Supervisor.terminate_child(Cell.Supervisor, pid)
  end

  test "destroy/1 terminates the cell with the given `position`" do
    position = {1, 4}
    {:ok, pid} = Cell.create(position)
    assert Cell.destroy(pid) == :ok
  end

  test "tick/1 returns no cells to create and its own pid to destroy" do
    position = {1, 6}
    {:ok, pid} = Cell.create(position)
    assert Cell.tick(pid) == {[], [pid]}
    Supervisor.terminate_child(Cell.Supervisor, pid)
  end

  test "tick/1 returns no cells to create, no cells to destroy" do
    position1 = {3, 0}
    position2 = {3, 1}
    position3 = {4, 0}
    position4 = {4, 1}
    {:ok, pid1} = Cell.create(position1)
    {:ok, pid2} = Cell.create(position2)
    {:ok, pid3} = Cell.create(position3)
    {:ok, pid4} = Cell.create(position4)
    assert Cell.tick(pid2) == {[], []}
    Supervisor.terminate_child(Cell.Supervisor, pid1)
    Supervisor.terminate_child(Cell.Supervisor, pid2)
    Supervisor.terminate_child(Cell.Supervisor, pid3)
    Supervisor.terminate_child(Cell.Supervisor, pid4)
  end

  test "tick/1 returns cells to create, no cells to destroy" do
    position1 = {6, 0}
    position2 = {6, 1}
    position3 = {6, 2}
    {:ok, pid1} = Cell.create(position1)
    {:ok, pid2} = Cell.create(position2)
    {:ok, pid3} = Cell.create(position3)
    assert Cell.tick(pid2) == {[{5, 1}, {7, 1}], []}
    Supervisor.terminate_child(Cell.Supervisor, pid1)
    Supervisor.terminate_child(Cell.Supervisor, pid2)
    Supervisor.terminate_child(Cell.Supervisor, pid3)
  end

  test "tick/1 returns cells to create and its own `pid` to destroy" do
    position1 = {30, 0}
    position2 = {30, 1}
    position3 = {30, 2}
    {:ok, pid1} = Cell.create(position1)
    {:ok, pid2} = Cell.create(position2)
    {:ok, pid3} = Cell.create(position3)
    assert Cell.tick(pid1) == {[{29, 1}, {31, 1}], [pid1]}
    Supervisor.terminate_child(Cell.Supervisor, pid1)
    Supervisor.terminate_child(Cell.Supervisor, pid2)
    Supervisor.terminate_child(Cell.Supervisor, pid3)
  end

  test "position/1 returns correct cell position" do
    position = {10, 0}
    {:ok, pid} = Cell.create(position)
    assert Cell.position(pid) == position
  end
end
