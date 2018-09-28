require "curses"

Curses.init_screen
begin
  s = "Hello World!"
  win = Curses::Window.new(Curses.lines / 1.8, Curses.cols, 1, 1)
  Curses.setpos(Curses.lines / 2, Curses.cols / 2 - (s.length / 2))
  Curses.addstr(s)
  Curses.refresh
  Curses.getch
ensure
  Curses.close_screen
end

