module stklng;
import std::io;
import std::collections;
import libc;

enum FunctionType {
    F_PUSH, // push to the stack
	F_POP, // pop stack[-1]
	F_ADDI, // add stack[-1] to stack[-2] (int)
	F_ADDF, // " but for float
	F_SCAT, // concat stack[-2] to stack[-1]
	F_ISUB, // subtract stack[-2] from stack[-1] (int)
	F_FSUB, // " but for float
	F_ICMP, // compare stack[-1] to stack[-2] and push the result as a bool
	F_FCMP, // " but for float
	F_SCMP, // " but for strings
	F_PRSTK, // print the stack
	F_PRINT, // print stack[-1]
	F_CALLCON, // call a different block if stack[-1] is bool `true`
	F_CALL, // call a different block unconditionally
    // DEPRECATED
	//F_RETURN, // return to the last block 
	F_SWP, // swap stack[-1] with stack[-2]
	F_DUP, // duplicate stack[-1]
    F_LDX, // load stack[-1] into X register
    F_LDXNP, // " without popping
    F_STX, // push value in X register to the stack
    F_LDY, // load stack[-1] into Y register
    F_LDYNP, // " without popping
    F_STY, // push value in Y register to the stack
    F_TYX, // transfer value from Y to X
    F_TXY, // transfer value from X to Y
    F_RDF, // read entire file (name in X) and push it to the stack as a string
    F_WTF, // write stack[-1] to file (name in X)
    F_ATF, // apend stack[-1] to file (name in X)
    F_CHKERR, // check if last value on the stack is an error, print it and exit if it is;
    F_SSPLT, // split stack[-1] at string in X
    F_PREG, // print registers
}

enum CmpType {
    EQ, // equal
    NE, // not equal
    LT, // less than
    LE, // less than or equal
    GT, // greater than
    GE, // greater than or equal
}

enum NodeType {
    STRING,
    INT,
    BOOL,
    FLOAT,
    ERR,
}

union Value {
    String v_string;
    int v_int;
    bool v_bool;
    float v_float;
}

// values on the stack are nodes to allow multiple types
// but still have type checking
struct Node {
    NodeType nodeType;
    Value value;
    usz line;
}

// this is like a function in other languages
struct Block {
    usz last_line;
    List(<Function>) functions;
}

// this is basically an instruction
struct Function {
    FunctionType functionType;
    Node operand;
    CmpType cmpType;
    usz line;
}

struct Program {
    Map(<String, Block>) blocks;
}

// print the entire stack
fn void sPrstk(List(<Node>) *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] prstk requires at least one value on the stack (Line %d)", line);
        libc::exit(1);
    }
    io::printn("----     Stack    ----");
    foreach (i, node: stack) {
        switch (node.nodeType) {
            case NodeType.INT: 
                io::printfn("%d Int: %d", i, node.value.v_int);
            case NodeType.STRING: 
                io::printfn("%d String: \"%s\"", i, node.value.v_string);
            case NodeType.BOOL:
                String booleanValue = "false"; 
                if (node.value.v_bool) {
                    booleanValue = "true";
                }
                io::printfn("%d Boolean: %s", i, booleanValue);
            case NodeType.FLOAT:
                io::printfn("%d Float: %f", i, node.value.v_float);
            case NodeType.ERR:
                io::printfn("%d ERROR: %s which occured in line %d", i, node.value.v_string, node.line);
            default:
                io::printf("%d Unknown Type: ", i);
                io::printn(node.value);
        }
    }
    io::printn("---- End of Stack ----");
}

// push node to the stack
fn void sPush(List(<Node>) *stack, Node node, usz line) {
    stack.push(node);
}

// pop multiple elements off the top of the stack
fn void sPopMany(List(<Node>) *stack, uint amount) {
    for (uint i = 0; i < amount; ++i) {
        //free(stack.last()!!.value.ptr);
        stack.pop()!!;
    }
}

// pop 1 element off the top of the stack
macro sPop(stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] pop requires at least one value on the stack (Line %d)", line);
        libc::exit(1);
    }
    sPopMany(stack, 1);
}

// add ints stack[-1] and stack[-2]
fn void sAddi(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] addi requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printfn("[ERROR] addi requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    int addend = stack.last().value.v_int!!;
    sPop(stack, line);
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printfn("[ERROR] addi requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    int addend2 = stack.last().value.v_int!!;
    sPop(stack, line);
    int result = addend + addend2;
    sPush(stack, {.nodeType = NodeType.INT, .value.v_int = result}, line);
}

// add floats stack[-1] and stack[-2]
fn void sAddf(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] addf requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] addf requires 2 floats on the stack (Line %d)", line, line);
        libc::exit(1);
    }
    float addend = stack.last().value.v_float!!;
    sPop(stack, line);
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] addf requires 2 floats on the stack (Line %d)", line, line);
        libc::exit(1);
    }
    float addend2 = stack.last().value.v_float!!;
    sPop(stack, line);
    float result = addend + addend2;
    sPush(stack, {.nodeType = NodeType.FLOAT, .value.v_float = result}, line);
}

// concat stack[-2] to stack[-1]
fn void sScat(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] scat requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] scat requires 2 strings on the stack (Line %d)", line);
        libc::exit(1);
    }
    String s1 = stack.last().value.v_string!!;
    sPop(stack, line);
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] scat requires 2 strings on the stack (Line %d)", line);
        libc::exit(1);
    }
    String s2 = stack.last().value.v_string!!;
    sPop(stack, line);
    String final = s1.concat(s2);
    sPush(stack, {.nodeType = NodeType.STRING, .value.v_string = final}, line);
}

// compare ints stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sIcmp(List(<Node>) *stack, CmpType cmp, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] icmp requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printfn("[ERROR] icmp requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.INT) {
        io::printfn("[ERROR] icmp requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    int i1 = stack.last().value.v_int!!;
    int i2 = stack.get(stack.len() - 2).value.v_int;
    bool result;
    switch (cmp) {
        case EQ:
            result = i1 == i2;
        case NE:
            result = i1 != i2;
        case LT:
            result = i1 < i2;
        case LE:
            result = i1 <= i2;
        case GT:
            result = i1 > i2;
        case GE:
            result = i1 >= i2;
    }
    sPush(stack, {.nodeType = NodeType.BOOL, .value.v_bool = result}, line);
}

// compare floats stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sFcmp(List(<Node>) *stack, CmpType cmp, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] fcmp requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] fcmp requires 2 floats on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] fcmp requires 2 floats on the stack (Line %d)", line);
        libc::exit(1);
    }
    float f1 = stack.last().value.v_float!!;
    float f2 = stack.get(stack.len() - 2).value.v_float;
    bool result;
    switch (cmp) {
        case EQ:
            result = f1 == f2;
        case NE:
            result = f1 != f2;
        case LT:
            result = f1 < f2;
        case LE:
            result = f1 <= f2;
        case GT:
            result = f1 > f2;
        case GE:
            result = f1 >= f2;
    }
    sPush(stack, {.nodeType = NodeType.BOOL, .value.v_bool = result}, line);
}

// compare strings stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sScmp(List(<Node>) *stack, CmpType cmp, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] scmp requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] scmp requires 2 Strings on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.STRING) {
        io::printfn("[ERROR] scmp requires 2 Strings on the stack (Line %d)", line);
        libc::exit(1);
    }
    String s1 = stack.last().value.v_string!!;
    String s2 = stack.get(stack.len() - 1).value.v_string;
    bool result;
    switch (cmp) {
        case EQ:
            result = s1 == s2;
        case NE:
            result = s1 != s2;
        default:
            io::printn("[ERROR] invalid cmptype for String");
            libc::exit(1);
    }
    sPush(stack, {.nodeType = NodeType.BOOL, .value.v_bool = result}, line);
}

// subtract floats stack[-2] from stack[-1]
fn void sIsub(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] isub requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printfn("[ERROR] isub requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    int minuend = stack.last().value.v_int!!;
    sPop(stack, line);
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printfn("[ERROR] isub requires 2 integers on the stack (Line %d)", line);
        libc::exit(1);
    }
    int subtrahend = stack.last().value.v_int!!;
    sPop(stack, line);
    int result = minuend - subtrahend;
    sPush(stack, {.nodeType = NodeType.INT, .value.v_int = result}, line);
}

// subtract integers stack[-2] from stack[-1]
fn void sFsub(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] fsub requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] fsub requires 2 floats on the stack (Line %d)", line);
        libc::exit(1);
    }
    float minuend = stack.last().value.v_float!!;
    sPop(stack, line);
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printfn("[ERROR] fsub requires 2 floats on the stack (Line %d)", line);
        libc::exit(1);
    }
    float subtrahend = stack.last().value.v_float!!;
    sPop(stack, line);
    float result = minuend - subtrahend;
    sPush(stack, {.nodeType = NodeType.FLOAT, .value.v_float = result}, line);
}

// swap stack[-1] with stack[-2]
fn void sSwp(List(<Node>) *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] swp requires at least 2 values on the stack (Line %d)", line);
        libc::exit(1);
    }
    stack.swap(stack.len() - 1, stack.len() - 2);
}

// duplicate stack[-1]
fn void sDup(List(<Node>) *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] dup requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    sPush(stack, node, line);
}

// print stack[-1]// append stack[-1] to the file with the filePath in X register
fn void sPrint(List(<Node>) *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] print requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    switch (node.nodeType) {
            case NodeType.INT: 
                io::printn(node.value.v_int);
            case NodeType.STRING: 
                io::printn(node.value.v_string);
            case NodeType.BOOL:
                String booleanValue = "false"; 
                if (node.value.v_bool) {
                    booleanValue = "true";
                }
                io::printn(booleanValue);
            case NodeType.FLOAT:
                io::printn(node.value.v_float);
            case NodeType.ERR:
                io::printfn("ERROR: %s", node.value.v_string);
            default:
                io::print("Unknown Type: "); // shouldnt happen?
                io::printn(node.value);
        }
}

// load stack[-1] into X
fn void sLdx(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldx requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    sPop(stack, line);
    registers.set("x", node);
}

// load stack[-1] into X
fn void sLdxnp(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldx requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    registers.set("x", node);
}

// push X to the stack
fn void sStx(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    sPush(stack, node, line);
}

// load stack[-1] into Y
fn void sLdy(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldy requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    sPop(stack, line);
    registers.set("y", node);
}

fn void sLdynp(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldy requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    Node node = stack.last()!!;
    registers.set("y", node);
}

// push Y to the stack
fn void sSty(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("y")!!;
    sPush(stack, node, line);
}

// transfer X to Y
fn void sTxy(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    registers.set("y", node);
}

// transfer Y to X
fn void sTyx(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("y")!!;
    registers.set("x", node);
}

// read entire file with the filePath in X and push the result onto the stack
fn void sRdf(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    if (node.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] rdf requires a String in the X register (Line %d)", line);
        libc::exit(1);
    }
    String! entireFile = (String)file::load_temp(node.value.v_string);
    if (try entireFile) {
        Node nodeToPush = {.nodeType = NodeType.STRING, .value.v_string = entireFile};
        sPush(stack, nodeToPush, line);
    } else {
        Node nodeToPush = {.nodeType = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, nodeToPush, line);
    }
}

// write stack[-1] to the file with the filePath in X register
fn void sWtf(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    if (node.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] wtf requires a String in the X register (Line %d)", line);
        libc::exit(1);
    }
    if (stack.len() < 1) {
        io::printfn("[ERROR] wtf requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] wtf requires a String on the stack (Line %d)", line);
        libc::exit(1);
    }
    File! toWrite = file::open(node.value.v_string, "w")!!;
    if (try toWrite) {
        usz! success = toWrite.write(stack.last().value.v_string!!);
        if (@catch(success)) {
            Node nodeToPush = {.nodeType = NodeType.ERR, .value.v_string = "FileWriteError", .line = line};
            sPush(stack, nodeToPush, line);
        }
        toWrite.close()!!;
    } else {
        Node nodeToPush = {.nodeType = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, nodeToPush, line);
    }
}

// append stack[-1] to the file with the filePath in X register
fn void sAtf(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    if (node.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] atf requires a String in the X register (Line %d)", line);
        libc::exit(1);
    }
    if (stack.len() < 1) {
        io::printfn("[ERROR] atf requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] atf requires a String on the stack (Line %d)", line);
        libc::exit(1);
    }
    File! toWrite = file::open(node.value.v_string, "a");
    if (try toWrite) {
        usz! success = toWrite.write(stack.last().value.v_string!!);
        if (@catch(success)) {
            Node nodeToPush = {.nodeType = NodeType.ERR, .value.v_string = "FileWriteError", .line = line};
            sPush(stack, nodeToPush, line);
        }
        toWrite.close()!!;
    } else {
        Node nodeToPush = {.nodeType = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, nodeToPush, line);
    }
}

// check if last item on the stack is an error
// if it is, print it and exit
fn void sChkerr(List(<Node>) *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] chkerr requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType == NodeType.ERR) {
        io::printfn("[ERROR] %s in chkerr (Line %d)", stack.last()!!.value.v_string, line);
        libc::exit(1);
    }
}

fn void sSsplt(List(<Node>) *stack, Map(<String, Node>) *registers, usz line) {
    Node node = registers.get("x")!!;
    if (node.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] ssplit requires a String in the X register (Line %d)", line);
        libc::exit(1);
    }
    if (stack.len() < 1) {
        io::printfn("[ERROR] ssplit requires at least 1 value on the stack (Line %d)", line);
        libc::exit(1);
    }
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printfn("[ERROR] ssplit requires a String on the stack (Line %d)", line);
        libc::exit(1);
    }
    String needle = node.value.v_string;
    String toSplit = stack.last().value.v_string!!;
    sPop(stack, line);
    String[] splits = toSplit.split(needle);
    foreach (split: splits) {
        Node nodeToPush = {.nodeType = NodeType.STRING, .value.v_string = split};
        sPush(stack, nodeToPush, line);
    }
}

fn void sPreg(Map(<String, Node>) *registers, usz line) {
    Node x = registers.get("x")!!;
    Node y = registers.get("y")!!;
    io::printn("---- Registers ----");
    switch (x.nodeType) {
        case NodeType.INT: 
            io::printfn("X -> Int: %d", x.value.v_int);
        case NodeType.STRING: 
            io::printfn("X -> String: \"%s\"", x.value.v_string);
        case NodeType.BOOL:
            String booleanValue = "false"; 
            if (x.value.v_bool) {
                booleanValue = "true";
            }
            io::printfn("X -> Bool: %s", booleanValue);
        case NodeType.FLOAT:
            io::printfn("X -> Float: %f", x.value.v_float);
        case NodeType.ERR:
            io::printfn("X -> ERROR: %s", x.value.v_string);
        default:
            io::print("X -> Unknown Type: "); // shouldnt happen?
            io::printn(x.value);
    }
    switch (y.nodeType) {
        case NodeType.INT: 
            io::printfn("Y -> Int: %d", y.value.v_int);
        case NodeType.STRING: 
            io::printfn("Y -> String: \"%s\"", y.value.v_string);
        case NodeType.BOOL:
            String booleanValue = "false"; 
            if (y.value.v_bool) {
                booleanValue = "true";
            }
            io::printfn("Y -> Bool: %s", booleanValue);
        case NodeType.FLOAT:
            io::printfn("X -> Float: %f",y.value.v_float);
        case NodeType.ERR:
            io::printfn("Y -> ERROR: %s", y.value.v_string);
        default:
            io::print("Y -> Unknown Type: "); // shouldnt happen?
            io::printn(y.value);
    }
    io::printn("-------------------");
}

// eval a single function and return `!` or the name of the next block/return
// to go back to the previous block
fn String eval(List(<Node>) *stack, Function *function, Map(<String, Node>) *registers) {
    switch (function.functionType) {
        case F_PUSH:
            sPush(stack, function.operand, function.line);
        case F_POP:     
            sPop(stack, function.line);
        case F_ADDI:
            sAddi(stack, function.line);
        case F_CALL:
            return function.operand.value.v_string;
        case F_PRSTK: 
            sPrstk(stack, function.line);
        //case F_RETURN:
        //    return "return";
        case F_CALLCON:
            if (stack.len() < 1) {
                io::printfn("[ERROR] callcon requires at least one value on the stack (Line %d)", function.line);
                libc::exit(1);
            }
            if (stack.last().nodeType!! != NodeType.BOOL) {
                io::printfn("[ERROR] callcon requires at least one boolean on the stack (Line %d)", function.line);
                libc::exit(1);
            }
            if (stack.last().value.v_bool!!) {
                return function.operand.value.v_string;
            }
        case F_SWP:
            sSwp(stack, function.line);
        case F_DUP:
            sDup(stack, function.line);
        case F_ISUB: 
            sIsub(stack, function.line);
        case F_FSUB:
            sFsub(stack, function.line);
        case F_ADDF:
            sAddf(stack, function.line);
        case F_SCAT:
            sScat(stack, function.line);
        case F_ICMP:
            sIcmp(stack, function.cmpType, function.line);
        case F_FCMP:
            sFcmp(stack, function.cmpType, function.line);
        case F_SCMP:
            sScmp(stack, function.cmpType, function.line);
        case F_PRINT:
            sPrint(stack, function.line);
        case F_LDX:
            sLdx(stack, registers, function.line);
        case F_LDXNP:
            sLdxnp(stack, registers, function.line);
        case F_LDY:
            sLdy(stack, registers, function.line);
        case F_LDYNP:
            sLdynp(stack, registers, function.line);
        case F_STX:
            sStx(stack, registers, function.line);
        case F_STY:
            sSty(stack, registers, function.line);
        case F_TYX:
            sTyx(stack, registers, function.line);
        case F_TXY:
            sTxy(stack, registers, function.line);
        case F_RDF:
            sRdf(stack, registers, function.line);
        case F_WTF:
            sWtf(stack, registers, function.line);
        case F_ATF:
            sAtf(stack, registers, function.line);
        case F_CHKERR:
            sChkerr(stack, function.line);
        case F_SSPLT:
            sSsplt(stack, registers, function.line);
        case F_PREG:
            sPreg(registers, function.line);
        default:
            io::printfn("[ERROR] FunctionType %s doesnt exist or is not implemented (Line %d)", function.line);
            libc::exit(1);
    }
    return "!"; // this means stay in the same block
}

// execute a block
fn String exec_block(List(<Node>) *stack, Program *program, Map(<String, Node>) *registers, Block* block) {
    usz i = 0;
    while (i < block.functions.len()) {
        String next_block = eval(stack, block.functions.get_ref(i), registers);
        if (next_block != "!") { // ! means no call
            return next_block;
        }
        ++i;
    }
    return "."; // . means execution finished
}

// execute program
fn void exec(List(<Node>) *stack, Program *program, Map(<String, Node>) *registers, String block, String lastBlock) {
    Block* current_block = program.blocks.get_ref(block)!!;
    String next_block = "none";
    while (next_block != ".") {
        //mem::@report_heap_allocs_in_scope() {
        next_block = exec_block(stack, program, registers, current_block);
        //};
        if (next_block == ".") {
            break;
        }
        current_block = program.blocks.get_ref(next_block)!!;
    }
    io::printn("[INFO] Execution finished");
}

fn void add_block_function(Block *b, Function f) {
    b.functions.push(f);
}

fn Block init_block() {
    Block b = {};
    b.last_line = 0;
    return b;
}

fn void add_block_to_program(Program *p, Block b, String b_name) {
    p.blocks.set(b_name, b);
}

// helper functions for createFromFile()

fn bool is_whitespace(String token) {
    for (usz i = 0; i < token.len; ++i) {
        if (token[i] != ' ') {
            return false;
        }
    }
    return true;
}

enum TokenType {
    KEYWORD,
    SYMBOL,
    INTEGER,
    FLOAT,
    STRING,
    PUNCT,
    BOOL,
}

struct Token {
    TokenType tokenType;
    String value;
    usz line;
}

String[] keywords = {
    "push",
    "pop",
    "addi",
    "addf",
    "scat",
    "isub",
    "fsub",
    "icmp",
    "fcmp",
    "scmp",
    "prstk",
    "print",
    "callcon",
    "call",
    //"return",
    "ldx",
    "ldxnp",
    "ldy",
    "ldynp",
    "stx",
    "sty",
    "txy",
    "tyx",
    "swp",
    "dup",
    "rdf",
    "wtf",
    "atf",
    "chkerr",
    "ssplt",
    "preg",
    "eq",
    "ne",
    "lt",
    "le",
    "gt",
    "ge",
};

String[] booleans = {
    "true",
    "false",
};

char[] numeric = {
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    '.',
    '-',
};

char[] puncts = {
    ';',
    ':',
    '!',
    '.',
};


// all of these should be self explanatory
fn bool is_keyword(String token) {
    foreach (keyword: keywords) {
        if (token == keyword) {
            return true;
        }
    }
    return false;
}

fn bool is_numeric(char c) {
    foreach (n: numeric) {
        if (c == n) {
            return true;
        }
    }
    return false;
}

// TODO: make sure theres only one - and if there is, it's 
// the first character
fn bool is_integer(String token) {
    for (usz i = 0; i < token.len; ++i) {
        if (!is_numeric(token[i])) {
            return false;
        }
        if (token[i] == '.') {
            return false;
        }
    }
    return true;
}


// TODO: make sure theres only one . and its not the first character
// semi fixed due to . being registered as a punct
fn bool is_float(String token) {
    for (usz i = 0; i < token.len; ++i) {
        if (!is_numeric(token[i])) {
            return false;
        }
    }
    return true;
}

fn bool is_punct(String token) {
    foreach (p: puncts) {
        if (token[0] == p) {
            return true;
        }
    }
    return false;
}

fn bool is_boolean(String token) {
    foreach (b: booleans) {
        if (token == b) {
            return true;
        }
    }
    return false;
}

fn void error_msg(String expected, Token token) {
    io::printf("[ERROR] Expected `%s`, got ", expected);
    io::print(token.tokenType);
    io::print(": ");
    io::print(token.value);
    io::printfn(" in line %d", token.line);
    libc::exit(1);
}

// create a Program struct containing blocks
// which can then get executed
fn Program createFromFile(String filePath, bool debug) {
    String entireFile = (String)file::load_temp(filePath)!!;
    String[] lines = entireFile.split("\n");
    List(<String>) tokenstrings;
    List(<usz>) indices;
    foreach (i, line: lines) {
        String[] line_tokens = line.split(" ");
        String string_literal = "";
        bool in_string_literal = false;
        foreach (token: line_tokens) {
            if (!in_string_literal) {
                if (token.starts_with("//")) {
                    break; // comments just dont get put in the tokens
                } else if (token.starts_with("#")) {
                    break; // for shebang
                }
                if (token.starts_with("\"")) { // string literal
                    in_string_literal = true;
                    if (token.ends_with("\";")) {
                        string_literal = token.strip_end(";");
                        in_string_literal = false;
                        tokenstrings.push(string_literal);
                        indices.push(i+1);
                        tokenstrings.push(";");
                        indices.push(i+1);
                    }
                    string_literal = token;
                } else {
                    if (!is_whitespace(token)) {
                        if (token.ends_with(";")) {
                            tokenstrings.push(token.strip_end(";"));
                            indices.push(i+1);
                            tokenstrings.push(";");
                            indices.push(i+1);
                        } else if (token.ends_with(":")) {
                            tokenstrings.push(token.strip_end(":"));
                            indices.push(i+1);
                            tokenstrings.push(":");
                            indices.push(i+1);
                        } else {
                            tokenstrings.push(token);
                            indices.push(i+1);
                        }
                    }
                }
            } else {
                if (!token.ends_with("\";")) {
                    string_literal = string_literal.tconcat(" ");
                    string_literal = string_literal.tconcat(token);
                } else {
                    string_literal = string_literal.tconcat(" ");
                    string_literal = string_literal.tconcat(token.strip_end(";"));
                    tokenstrings.push(string_literal);
                    indices.push(i+1);
                    tokenstrings.push(";");
                    indices.push(i+1);
                    in_string_literal = false;
                }
            }
        } 
    }

    List(<Token>) tokens;
    foreach (i, tokenstring: tokenstrings) { // TODO: rewrite as switch(true) / just switch
        if (is_keyword(tokenstring)) {
            tokens.push({.tokenType = KEYWORD, .value = tokenstring, .line = indices.get(i)});
        } else if (is_integer(tokenstring)) {
            tokens.push({.tokenType = INTEGER, .value = tokenstring.strip("_"), .line = indices.get(i)});
        } else if (tokenstring.starts_with("\"")) {
            tokens.push({.tokenType = STRING, .value = tokenstring.strip("\"").strip_end("\""), .line = indices.get(i)});
        } else if (is_float(tokenstring)) {
            tokens.push({.tokenType = FLOAT, .value = tokenstring, .line = indices.get(i)});
        } else if (is_punct(tokenstring)) {
            tokens.push({.tokenType = PUNCT, .value = tokenstring, .line = indices.get(i)});
        } else if (is_boolean(tokenstring)) {
            tokens.push({.tokenType = BOOL, .value = tokenstring, .line = indices.get(i)});
        } else {
            tokens.push({.tokenType = SYMBOL, .value = tokenstring, .line = indices.get(i)});
        }
    }
    if (debug) {
        io::printn("-------- Tokens --------");
        foreach (token: tokens) {
            io::print("    ");
            io::printn(token);
        }
        io::printn("-------- Tokens --------\n");
    }

    Program p = {};
    usz tokenIndex = 0;
   
    if (tokens.len() == 0) {
        libc::exit(0);
    }
    if (tokens[tokenIndex].tokenType != SYMBOL) { // make sure theres a block at the start
        io::printn("[ERROR] File needs to start with a block");
        libc::exit(0);
    }
    while (tokenIndex < tokens.len()) {
        if (tokens[tokenIndex].tokenType == SYMBOL) {
            Block b;
            b.last_line = 0;
            String block_name = tokens[tokenIndex].value;

            tokenIndex += 1;

            if (tokens[tokenIndex].tokenType != PUNCT) { // expect :
                error_msg(":", tokens[tokenIndex]);
            }

            tokenIndex += 1;

            while (tokenIndex < tokens.len() && tokens[tokenIndex + 1].value != ":") {
                if (tokens[tokenIndex].tokenType != KEYWORD) {
                    error_msg("keyword", tokens[tokenIndex]);
                }
                switch (tokens[tokenIndex].value) {
                    case ("push"):
                        tokenIndex += 1;
                        switch (tokens[tokenIndex].tokenType) {
                            case STRING:
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.STRING, .value.v_string = tokens[tokenIndex].value}, .line = tokens[tokenIndex].line});
                            case BOOL:
                                bool val;
                                if (tokens[tokenIndex].value == "true") {
                                    val = true;
                                } else {
                                    val = false;
                                }
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.BOOL, .value.v_bool = val}, .line = tokens[tokenIndex].line});
                            case INTEGER:
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.INT, .value.v_int = tokens[tokenIndex].value.to_int()!!}, .line = tokens[tokenIndex].line});
                            case FLOAT:
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.FLOAT, .value.v_float = tokens[tokenIndex].value.to_float()!!}, .line = tokens[tokenIndex].line});
                            default:
                                error_msg("String, bool, int or float", tokens[tokenIndex]);
                        }
                    case ("print"):
                        add_block_function(&b, {.functionType = F_PRINT, .line = tokens[tokenIndex].line});
                    case ("swp"):
                        add_block_function(&b, {.functionType = F_SWP, .line = tokens[tokenIndex].line});
                    case ("dup"):
                        add_block_function(&b, {.functionType = F_DUP, .line = tokens[tokenIndex].line});
                    case ("icmp"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != KEYWORD) {
                            error_msg("comparison type", tokens[tokenIndex]);
                        }
                        switch (tokens[tokenIndex].value) {
                            case ("eq"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = EQ, .line = tokens[tokenIndex].line});
                            case ("ne"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = NE, .line = tokens[tokenIndex].line});
                            case ("lt"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = LT, .line = tokens[tokenIndex].line});
                            case ("le"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = LE, .line = tokens[tokenIndex].line});
                            case ("gt"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = GT, .line = tokens[tokenIndex].line});
                            case ("ge"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = GE, .line = tokens[tokenIndex].line});
                            default:
                                error_msg("comparison type", tokens[tokenIndex]);
                        }
                    case ("callcon"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != SYMBOL) {
                            error_msg("block name", tokens[tokenIndex]);
                        }
                        add_block_function(&b, {.functionType = F_CALLCON, .operand = {.nodeType = NodeType.STRING, .value.v_string = tokens[tokenIndex].value}, .line = tokens[tokenIndex].line});
                    case ("call"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != SYMBOL) {
                            error_msg("block name", tokens[tokenIndex]);
                        }
                        add_block_function(&b, {.functionType = F_CALL, .operand = {.nodeType = NodeType.STRING, .value.v_string = tokens[tokenIndex].value}, .line = tokens[tokenIndex].line});
                    case ("prstk"):
                        add_block_function(&b, {.functionType = F_PRSTK, .line = tokens[tokenIndex].line});
                    case ("pop"):
                        add_block_function(&b, {.functionType = F_POP, .line = tokens[tokenIndex].line});
                    case ("isub"):
                        add_block_function(&b, {.functionType = F_ISUB, .line = tokens[tokenIndex].line});
                    case ("addi"):
                        add_block_function(&b, {.functionType = F_ADDI, .line = tokens[tokenIndex].line});
                    //case ("return"):
                    //    add_block_function(&b, {.functionType = F_RETURN, .line = tokens[tokenIndex].line});
                    case ("ldx"):
                        add_block_function(&b, {.functionType = F_LDX, .line = tokens[tokenIndex].line});
                    case ("ldxnp"):
                        add_block_function(&b, {.functionType = F_LDXNP, .line = tokens[tokenIndex].line});
                    case ("ldynp"):
                        add_block_function(&b, {.functionType = F_LDY, .line = tokens[tokenIndex].line});
                    case ("ldy"):
                        add_block_function(&b, {.functionType = F_LDYNP, .line = tokens[tokenIndex].line});
                    case ("stx"):
                        add_block_function(&b, {.functionType = F_STX, .line = tokens[tokenIndex].line});
                    case ("sty"):
                        add_block_function(&b, {.functionType = F_STY, .line = tokens[tokenIndex].line});
                    case ("txy"):
                        add_block_function(&b, {.functionType = F_TXY, .line = tokens[tokenIndex].line});
                    case ("tyx"):
                        add_block_function(&b, {.functionType = F_TYX, .line = tokens[tokenIndex].line});
                    case ("rdf"):
                        add_block_function(&b, {.functionType = F_RDF, .line = tokens[tokenIndex].line});
                    case ("wtf"):
                        add_block_function(&b, {.functionType = F_WTF, .line = tokens[tokenIndex].line});
                    case ("atf"):
                        add_block_function(&b, {.functionType = F_ATF, .line = tokens[tokenIndex].line});
                    case ("chkerr"):
                        add_block_function(&b, {.functionType = F_CHKERR, .line = tokens[tokenIndex].line});
                    case ("ssplt"):
                        add_block_function(&b, {.functionType = F_SSPLT, .line = tokens[tokenIndex].line});
                    case ("preg"):
                        add_block_function(&b, {.functionType = F_PREG, .line = tokens[tokenIndex].line});
                    default:
                        io::printfn("%s not implemented or does not exist (Line %d)", tokens[tokenIndex].value, tokens[tokenIndex].line);
                        libc::exit(1);
                }
                tokenIndex += 1;
                // TODO: actually check it's ; and not : or !
                if (tokens[tokenIndex].tokenType != PUNCT) { // expect ;
                    error_msg(";", tokens[tokenIndex]);
                }
                tokenIndex += 1;
            }
            if (debug) {
                io::printn("-------- Functions --------");
                foreach (f: b.functions) {
                    io::printf("    %s: ", block_name);
                    io::printn(f);
                }
                io::printn("-------- Functions --------\n");
            }
            add_block_to_program(&p, b, block_name);
        }        
    }
    return p;
}

fn int main(String[] args) {
    if (args.len < 2) {
        io::printn("[ERROR] You need to supply a file.");
        return 1;
    }
    bool debug = false;
    if (args.len > 2) {
        if (args[2] == "debug") {
            debug = true; // to print debug info in createFromFile
        }
    }

    // initialize stuff
    String filePath = args[1];
    Program p = createFromFile(filePath, debug);
    List(<Node>) stack;
    stack.new_init(initial_capacity: 1024);
    Map(<String, Node>) registers;
    registers.set("x", {.nodeType = NodeType.INT, .value.v_int = 0});
    registers.set("y", {.nodeType = NodeType.INT, .value.v_int = 0});

    if (!p.blocks.has_key("main")) { // make sure theres a main
        io::printn("[ERROR] No main block.");
        return 1;
    }
    if (debug) {
        mem::@report_heap_allocs_in_scope() {
            exec(&stack, &p, &registers, "main", "none");
            io::printn("\n----- Debug -----");
        };
    } else {
        exec(&stack, &p, &registers, "main", "none");
    }

    return 0;
}