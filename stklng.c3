module stklng;
import std::io;
import std::collections;

enum FunctionType {
    F_PUSH,
    F_POP,
    F_ADDI,
}

struct Block {
    List(<Function>) functions;
}

struct Function {
    FunctionType functionType;
    any operand;
}

struct Program {
    Map(<String, Block>) blocks;
}

fn void sPrstk(List(<any>) *stack) {
    io::printn("----     Stack    ----");
    foreach (value: stack) {
        switch (value) {
            case int: 
                io::printfn("Int: %d", *value);
            case String: 
                io::printfn("String: \"%S\"", *value);
            case bool:
                String booleanValue = "false"; 
                if ((bool)*value) {
                    booleanValue = "true";
                }
                io::printfn("Boolean: %s", booleanValue);
            case float:
                io::printfn("Float: %d", *value);
        }
    }
    io::printn("---- End of Stack ----");
}

fn void sPush(List(<any>) *stack, any value) {
    stack.push(value);
}

fn void sPopMany(List(<any>) *stack, uint amount) {
    for (uint i = 0; i < amount; ++i) {
        stack.pop()!!;
    }
}

macro sPop(stack) {
    sPopMany(stack, 1);
}

fn void sAddi(List(<any>) *stack, ) {
    // TODO: error handling
    int addend = *(int*)stack.last()!!;
    sPop(stack);
    int addend2 = *(int*)stack.last()!!;
    sPop(stack);
    sPush(stack, mem::@tclone(addend + addend2));
}

fn void eval(List(<any>) *stack, Function function) {
    switch (function.functionType) {
        case F_PUSH:
            sPush(stack, function.operand);
        case F_POP: 
            sPop(stack);
        case F_ADDI:
            sAddi(stack);
        default:
            unreachable();

    }
}

fn void exec(List(<any>) *stack, Program program) {
    Block main = program.blocks.get("main")!!;
    foreach (function: main.functions) {
        eval(stack, function);
    }
}

fn void main(String[] args) {
    Program p;
    List(<any>) stack;
    Block main = {};
    main.functions.push({.functionType = F_PUSH, .operand = mem::@tclone(34)});
    main.functions.push({.functionType = F_PUSH, .operand = mem::@tclone(35)});
    main.functions.push({.functionType = F_ADDI});
    p.blocks.set("main", main);
    exec(&stack, p);
    sPrstk(&stack);
}