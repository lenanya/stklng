// test?
main:
    push true;
    callcon test; // comment test moment
    prstk; // another;: 59 one?
test:
    callcon test2;
    return;
test2:
    prstk;
    return;