#!/usr/bin/stklng
main:
    push 0;
    push 2147483647;
    ldx;
    call loop_begin;
loop_begin:
    stx;
    swp;
    icmp le;
    callcon loop;
loop:
    pop;
    swp;
    pop;
    push 1;
    addi;
    //print;
    call loop_begin;
