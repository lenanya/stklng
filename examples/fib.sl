main:
    push 0;
    push 1;
    print;
    push 25;
    ldy;
    pop;
    call loop;
loop:
    push 1;
    sty;
    isub;
    ldy;
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
    ldx;
    swp;
    stx;
    addi;
    print;
    return;
