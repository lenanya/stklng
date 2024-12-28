main:
    push 69;
    push 420;
    swp;
    dup;
    callcon test;
    push "hi";
    print;
test:
    prstk;
    pop;
    print;
    push 4;
    push 39;
    isub;
    push 34;
    addi;
    prstk;
    call blob;
    return;
blob:
    prstk;
    prstk;
    prstk;
    return;