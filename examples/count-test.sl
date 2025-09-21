#!/usr/bin/stklng
main:
    push 0;
    push 1000000;
    ldx;
    call loop_begin;
loop_begin:
    stx;
    swp;
    icmp lt;
    callcon loop;
loop:
    pop;
    swp;
    pop;
    push 1;
    addi;
    print;
    call loop_begin;
