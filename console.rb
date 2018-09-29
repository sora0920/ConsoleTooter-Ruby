require "curses"
require_relative "./timeline.rb"

Curses.init_screen
begin
  s = "Hello World!"
  win = Curses::Window.new(Curses.lines / 1.8, Curses.cols, 1, 1)
  #win.addstr(s)
  stream(account, tl, param, img, safe)
  loop do
    win.refresh
  end
  win.close
ensure
  Curses.close_screen
end

