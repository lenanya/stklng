main:
    push 0;
    push 1;
    print;
    push 25;
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
    prstk;
    preg;
    callcon nextfib;
nextfib:
    pop;
    ldxnp;
    swp;
    stx;
    addi;
    print;
    call loop;
