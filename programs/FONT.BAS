graphicsmode
x = 10
y = 10

rem --- A ---
vline x y 4 10
x = x + 5
vline x y 4 10
x = x - 5
y = y + 5
hline x y 2 10
y = y - 5
hline x y 2 10

main:
getkey z
if z = 'e' then end
goto main
