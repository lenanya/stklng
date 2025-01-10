#!/usr/bin/stklng
main:
    push 0;
    push 1;
    print;
    push 184;
    ldynp;
    pop;
    call loop;
loop:
    push 1;
    sty;
    isub;
    ldynp;
    push 0;
    swp;
    icmp gt;
    swp;
    pop;
    swp;
    pop;
    callcon nextfib;
nextfib:
    pop;
    ldxnp;
    swp;
    stx;
    addi;
    print;
    call loop;
