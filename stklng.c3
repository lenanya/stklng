module stklng;
import std::io;
import std::collections;

enum FunctionType {
    F_PUSH,
	F_POP,
	F_POP_MANY,
	F_ADDI,
	F_ADDF,
	F_SCAT,
	F_ISUB,
	F_FSUB,
	F_ICMP,
	F_FCMP,
	F_SCMP,
	F_PRSTK,
	F_PRINT,
	F_CALLCON,
	F_CALL,
	F_RETURN,
	F_SWP,
	F_CSTR,
	F_DUP,
}

struct Block {
    usz last_line;
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

fn String eval(List(<any>) *stack, Function function) {
    switch (function.functionType) {
        case F_PUSH:
            sPush(stack, function.operand);
        case F_POP:     
            sPop(stack);
        case F_ADDI:
            sAddi(stack);
        case F_CALL:
            return *(String*)function.operand;
        case F_PRSTK: 
            sPrstk(stack);
        case F_RETURN:
            return "return";
        case F_CALLCON:
            if (*(bool*)stack.last()!!) {
                return *(String*)function.operand;
            }
        default:
            unreachable();

    }
    return "!";
}

fn void exec(List(<any>) *stack, Program program, String block, String lastBlock) {
    Block current_block = program.blocks.get(block)!!;
    usz i = current_block.last_line;
    while (i < current_block.functions.len()) {
        current_block.last_line = i + 1;
        String next_block = eval(stack, current_block.functions[i]);
        if (next_block != "!") {
            if (next_block == "return") {
                current_block.last_line = 0;
                program.blocks.set(block, current_block);
                i = current_block.functions.len() + 1;
                exec(stack, program, lastBlock, block);
            } else {
                program.blocks.set(block, current_block);
                i = current_block.functions.len() + 1;
                exec(stack, program, next_block, block);
            }
        }
        ++i;
    }
}

fn void main(String[] args) {
    Program p;
    List(<any>) stack;
    Block main = {};
    Block test = {};
    main.last_line = 0;
    test.last_line = 0;
    test.functions.push({.functionType = F_PUSH, .operand = mem::@tclone(420)});
    test.functions.push({.functionType = F_PRSTK});
    test.functions.push({.functionType = F_RETURN});
    main.functions.push({.functionType = F_PUSH, .operand = mem::@tclone(false)});
    main.functions.push({.functionType = F_CALLCON, .operand = mem::@tclone("test")});
    main.functions.push({.functionType = F_PRSTK});
    main.functions.push({.functionType = F_PUSH, .operand = mem::@tclone(true)});
    main.functions.push({.functionType = F_CALLCON, .operand = mem::@tclone("test")});
    main.functions.push({.functionType = F_PRSTK});
    p.blocks.set("main", main);
    p.blocks.set("test", test);
    exec(&stack, p, "main", "none");
}