main:
    push true;
    callcon test;
    prstk;
test:
    callcon test2;
    return;
test2:
    prstk;
    return;