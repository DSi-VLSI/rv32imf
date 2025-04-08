.include "startup.s"

main:
    li a1, 200
    csrr a2, TIME
    blt a2, a1, main
    li a0, 0
    ret
