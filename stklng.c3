module stklng;
import std::io;
import std::collections;

faultdef
    FILE_DOESNT_START_WITH_BLOCK,
    NO_MAIN_BLOCK,
    UNEXPECTED_TOKEN,
    COMPILE_TIME_OTHER_ERROR,
    EMPTY_FILE,
    NOT_IMPLEMENTED,
    TOO_FEW_VALUES_ON_STACK,
    STACK_TYPE_MISMATCH,
    INVALID_COMPARISON,
    REGISTER_TYPE_MISMATCH,
    RUNTIME_OTHER_ERROR;

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
    int128 v_int;
    bool v_bool;
    float v_float;
}

// values on the stack are nodes to allow multiple types
// but still have type checking
struct Node {
    NodeType node_type;
    Value value;
    usz line;
}

// this is like a function in other languages
struct Block {
    usz last_line;
    List{Function} functions;
}

// this is basically an instruction
struct Function {
    FunctionType function_type;
    Node operand;
    CmpType cmp_type;
    usz line;
}

struct Program {
    HashMap{String, Block} blocks;
}

fn void? _exit(fault code) {
    return code?;
}

// print the entire stack
fn void sPrstk(List{Node} *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] prstk requires at least one value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    io::printn("----     Stack    ----");
    foreach (i, node: stack) {
        switch (node.node_type) {
            case NodeType.INT:
                io::printfn("%d Int: %d", i, node.value.v_int);
            case NodeType.STRING:
                io::printfn("%d String: \"%s\"", i, node.value.v_string);
            case NodeType.BOOL:
                String boolean_value = "false";
                if (node.value.v_bool) {
                    boolean_value = "true";
                }
                io::printfn("%d Boolean: %s", i, boolean_value);
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
fn void sPush(List{Node} *stack, Node node, usz line) {
    stack.push(node);
}

// pop multiple elements off the top of the stack
fn void sPopMany(List{Node} *stack, uint amount) {
    for (uint i = 0; i < amount; ++i) {
        stack.pop()!!;
    }
}

// pop 1 element off the top of the stack
macro sPop(stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] pop requires at least one value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    sPopMany(stack, 1);
}

// add ints stack[-1] and stack[-2]
fn void sAddi(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] addi requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.INT:
            io::printfn("[ERROR] addi requires 2 integers on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    int128 addend = stack.last().value.v_int!!;
    sPop(stack, line);
    if (stack.last()!!.node_type != NodeType.INT) {
        io::printfn("[ERROR] addi requires 2 integers on the stack (Line %d)", line);
        _exit(STACK_TYPE_MISMATCH)!!;
    }
    int128 addend2 = stack.last().value.v_int!!;
    sPop(stack, line);
    int128 result = addend + addend2;
    sPush(stack, {.node_type = NodeType.INT, .value.v_int = result}, line);
}

// add floats stack[-1] and stack[-2]
fn void sAddf(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] addf requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.FLOAT:
            io::printfn("[ERROR] addf requires 2 floats on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }
    float addend = stack.last().value.v_float!!;
    sPop(stack, line);
    if (stack.last()!!.node_type != NodeType.FLOAT) {
        io::printfn("[ERROR] addf requires 2 floats on the stack (Line %d)", line);
        _exit(STACK_TYPE_MISMATCH)!!;
    }
    float addend2 = stack.last().value.v_float!!;
    sPop(stack, line);
    float result = addend + addend2;
    sPush(stack, {.node_type = NodeType.FLOAT, .value.v_float = result}, line);
}

// concat stack[-2] to stack[-1]
fn void sScat(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] scat requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.STRING:
            io::printfn("[ERROR] scat requires 2 strings on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    String s1 = stack.last().value.v_string!!;
    sPop(stack, line);
    if (stack.last()!!.node_type != NodeType.STRING) {
        io::printfn("[ERROR] scat requires 2 strings on the stack (Line %d)", line);
        _exit(STACK_TYPE_MISMATCH)!!;
    }
    String s2 = stack.last().value.v_string!!;
    sPop(stack, line);
    String final = s1.concat(mem, s2);
    sPush(stack, {.node_type = NodeType.STRING, .value.v_string = final}, line);
}

// compare ints stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sIcmp(List{Node} *stack, CmpType cmp, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] icmp requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.INT:
            io::printfn("[ERROR] icmp requires 2 integers on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
        case stack.get(stack.len() - 2).node_type != NodeType.INT:
            io::printfn("[ERROR] icmp requires 2 integers on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    int128 i1 = stack.last().value.v_int!!;
    int128 i2 = stack.get(stack.len() - 2).value.v_int;
    bool result;
    switch (cmp) {
        case EQ: result = i1 == i2;
        case NE: result = i1 != i2;
        case LT: result = i1 < i2;
        case LE: result = i1 <= i2;
        case GT: result = i1 > i2;
        case GE: result = i1 >= i2;
    }
    sPush(stack, {.node_type = NodeType.BOOL, .value.v_bool = result}, line);
}

// compare floats stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sFcmp(List{Node} *stack, CmpType cmp, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] fcmp requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.FLOAT:
            io::printfn("[ERROR] fcmp requires 2 floats on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
        case stack.get(stack.len() - 2).node_type != NodeType.FLOAT:
            io::printfn("[ERROR] fcmp requires 2 floats on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    float f1 = stack.last().value.v_float!!;
    float f2 = stack.get(stack.len() - 2).value.v_float;
    bool result;
    switch (cmp) {
        case EQ: result = f1 == f2;
        case NE: result = f1 != f2;
        case LT: result = f1 < f2;
        case LE: result = f1 <= f2;
        case GT: result = f1 > f2;
        case GE: result = f1 >= f2;
    }
    sPush(stack, {.node_type = NodeType.BOOL, .value.v_bool = result}, line);
}

// compare strings stack[-1] to stack[-2] and push a bool
// depending on the result of the cmptype
fn void sScmp(List{Node} *stack, CmpType cmp, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] scmp requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.STRING:
            io::printfn("[ERROR] scmp requires 2 Strings on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
        case stack.get(stack.len() - 2).node_type != NodeType.STRING:
            io::printfn("[ERROR] scmp requires 2 Strings on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    String s1 = stack.last().value.v_string!!;
    String s2 = stack.get(stack.len() - 1).value.v_string;
    bool result;
    switch (cmp) {
        case EQ: result = s1 == s2;
        case NE: result = s1 != s2;
        default:
            io::print("[ERROR] invalid cmptype for String");
            _exit(INVALID_COMPARISON)!!;
    }
    sPush(stack, {.node_type = NodeType.BOOL, .value.v_bool = result}, line);
}

// subtract floats stack[-2] from stack[-1]
fn void sIsub(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] isub requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.INT:
            io::printfn("[ERROR] isub requires 2 integers on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    int128 minuend = stack.last().value.v_int!!;
    sPop(stack, line);
    if (stack.last()!!.node_type != NodeType.INT) {
        io::printfn("[ERROR] isub requires 2 integers on the stack (Line %d)", line);
        _exit(STACK_TYPE_MISMATCH)!!;
    }
    int128 subtrahend = stack.last().value.v_int!!;
    sPop(stack, line);
    int128 result = minuend - subtrahend;
    sPush(stack, {.node_type = NodeType.INT, .value.v_int = result}, line);
}

// subtract integers stack[-2] from stack[-1]
fn void sFsub(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 2:
            io::printfn("[ERROR] fsub requires at least 2 values on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.FLOAT:
            io::printfn("[ERROR] fsub requires 2 floats on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    float minuend = stack.last().value.v_float!!;
    sPop(stack, line);
    if (stack.last()!!.node_type != NodeType.FLOAT) {
        io::printfn("[ERROR] fsub requires 2 floats on the stack (Line %d)", line);
        _exit(STACK_TYPE_MISMATCH)!!;
    }
    float subtrahend = stack.last().value.v_float!!;
    sPop(stack, line);
    float result = minuend - subtrahend;
    sPush(stack, {.node_type = NodeType.FLOAT, .value.v_float = result}, line);
}

// swap stack[-1] with stack[-2]
fn void sSwp(List{Node} *stack, usz line) {
    if (stack.len() < 2) {
        io::printfn("[ERROR] swp requires at least 2 values on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    stack.swap(stack.len() - 1, stack.len() - 2);
}

// duplicate stack[-1]
fn void sDup(List{Node} *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] dup requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    sPush(stack, node, line);
}

// print stack[-1]// append stack[-1] to the file with the file_path in X register
fn void sPrint(List{Node} *stack, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] print requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    switch (node.node_type) {
            case NodeType.INT:
                io::printn(node.value.v_int);
            case NodeType.STRING:
                io::printn(node.value.v_string);
            case NodeType.BOOL:
                String boolean_value = "false";
                if (node.value.v_bool) boolean_value = "true";
                io::printn(boolean_value);
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
fn void sLdx(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldx requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    sPop(stack, line);
    registers.set("x", node);
}

// load stack[-1] into X
fn void sLdxnp(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldxnp requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    registers.set("x", node);
}

// push X to the stack
fn void sStx(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;
    sPush(stack, node, line);
}

// load stack[-1] into Y
fn void sLdy(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldy requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    sPop(stack, line);
    registers.set("y", node);
}

fn void sLdynp(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    if (stack.len() < 1) {
        io::printfn("[ERROR] ldynp requires at least 1 value on the stack (Line %d)", line);
        _exit(TOO_FEW_VALUES_ON_STACK)!!;
    }
    Node node = stack.last()!!;
    registers.set("y", node);
}

// push Y to the stack
fn void sSty(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("y")!!;
    sPush(stack, node, line);
}

// transfer X to Y
fn void sTxy(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;
    registers.set("y", node);
}

// transfer Y to X
fn void sTyx(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("y")!!;
    registers.set("x", node);
}

// read entire file with the file_path in X and push the result onto the stack
fn void sRdf(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;
    if (node.node_type != NodeType.STRING) {
        io::printfn("[ERROR] rdf requires a String in the X register (Line %d)", line);
        _exit(REGISTER_TYPE_MISMATCH)!!;
    }
    String? entire_file = (String)file::load_temp(node.value.v_string);
    if (try entire_file) {
        Node node_to_push = {.node_type = NodeType.STRING, .value.v_string = entire_file};
        sPush(stack, node_to_push, line);
    } else {
        Node node_to_push = {.node_type = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, node_to_push, line);
    }
}

// write stack[-1] to the file with the file_path in X register
fn void sWtf(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;

    switch {
        case node.node_type != NodeType.STRING:
            io::printfn("[ERROR] wtf requires a String in the X register (Line %d)", line);
            _exit(REGISTER_TYPE_MISMATCH)!!;
        case stack.len() < 1:
            io::printfn("[ERROR] wtf requires at least 1 value on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.STRING:
            io::printfn("[ERROR] wtf requires a String on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    File? to_write = file::open(node.value.v_string, "w")!!;
    if (try to_write) {
        usz? success = to_write.write(stack.last().value.v_string!!);
        if (@catch(success)) {
            Node node_to_push = {.node_type = NodeType.ERR, .value.v_string = "FileWriteError", .line = line};
            sPush(stack, node_to_push, line);
        }
        to_write.close()!!;
    } else {
        Node node_to_push = {.node_type = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, node_to_push, line);
    }
}

// append stack[-1] to the file with the file_path in X register
fn void sAtf(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;

    switch {
        case node.node_type != NodeType.STRING:
            io::printfn("[ERROR] atf requires a String in the X register (Line %d)", line);
            _exit(REGISTER_TYPE_MISMATCH)!!;
        case stack.len() < 1:
            io::printfn("[ERROR] atf requires at least 1 value on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.STRING:
            io::printfn("[ERROR] atf requires a String on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    File? to_write = file::open(node.value.v_string, "a");
    if (try to_write) {
        usz? success = to_write.write(stack.last().value.v_string!!);
        if (@catch(success)) {
            Node node_to_push = {.node_type = NodeType.ERR, .value.v_string = "FileWriteError", .line = line};
            sPush(stack, node_to_push, line);
        }
        to_write.close()!!;
    } else {
        Node node_to_push = {.node_type = NodeType.ERR, .value.v_string = "FileNotFound", .line = line};
        sPush(stack, node_to_push, line);
    }
}

// check if last item on the stack is an error
// if it is, print it and exit
fn void sChkerr(List{Node} *stack, usz line) {
    switch {
        case stack.len() < 1:
            io::printfn("[ERROR] chkerr requires at least 1 value on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type == NodeType.ERR:
            io::printfn("[ERROR] %s in chkerr (Line %d)", stack.last()!!.value.v_string, line);
            _exit(RUNTIME_OTHER_ERROR)!!;
    }
}

fn void sSsplt(List{Node} *stack, HashMap{String, Node} *registers, usz line) {
    Node node = registers.get("x")!!;

    switch {
        case node.node_type != NodeType.STRING:
            io::printfn("[ERROR] ssplit requires a String in the X register (Line %d)", line);
            _exit(REGISTER_TYPE_MISMATCH)!!;
        case stack.len() < 1:
            io::printfn("[ERROR] ssplit requires at least 1 value on the stack (Line %d)", line);
            _exit(TOO_FEW_VALUES_ON_STACK)!!;
        case stack.last()!!.node_type != NodeType.STRING:
            io::printfn("[ERROR] ssplit requires a String on the stack (Line %d)", line);
            _exit(STACK_TYPE_MISMATCH)!!;
    }

    String needle = node.value.v_string;
    String to_split = stack.last().value.v_string!!;
    sPop(stack, line);
    String[] splits = to_split.split(mem, needle);
    foreach (split: splits) {
        Node node_to_push = {
            .node_type = NodeType.STRING,
            .value.v_string = split
        };
        sPush(stack, node_to_push, line);
    }
}

fn void sPreg(HashMap{String, Node} *registers, usz line) {
    Node x = registers.get("x")!!;
    Node y = registers.get("y")!!;
    io::printn("---- Registers ----");
    switch (x.node_type) {
        case NodeType.INT:
            io::printfn("X -> Int: %d", x.value.v_int);
        case NodeType.STRING:
            io::printfn("X -> String: \"%s\"", x.value.v_string);
        case NodeType.BOOL:
            String boolean_value = "false";
            if (x.value.v_bool) boolean_value = "true";
            io::printfn("X -> Bool: %s", boolean_value);
        case NodeType.FLOAT:
            io::printfn("X -> Float: %f", x.value.v_float);
        case NodeType.ERR:
            io::printfn("X -> ERROR: %s", x.value.v_string);
        default:
            io::print("X -> Unknown Type: "); // shouldnt happen?
            io::printn(x.value);
    }
    switch (y.node_type) {
        case NodeType.INT:
            io::printfn("Y -> Int: %d", y.value.v_int);
        case NodeType.STRING:
            io::printfn("Y -> String: \"%s\"", y.value.v_string);
        case NodeType.BOOL:
            String boolean_value = "false";
            if (y.value.v_bool) boolean_value = "true";
            io::printfn("Y -> Bool: %s", boolean_value);
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
fn String eval(List{Node} *stack, Function *function, HashMap{String, Node} *registers) {
    switch (function.function_type) {
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
        case F_CALLCON:
            if (stack.len() < 1) {
                io::printfn("[ERROR] callcon requires at least one value on the stack (Line %d)", function.line);
                _exit(TOO_FEW_VALUES_ON_STACK)!!;
            }
            if (stack.last().node_type!! != NodeType.BOOL) {
                io::printfn("[ERROR] callcon requires at least one boolean on the stack (Line %d)", function.line);
                _exit(STACK_TYPE_MISMATCH)!!;
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
            sIcmp(stack, function.cmp_type, function.line);
        case F_FCMP:
            sFcmp(stack, function.cmp_type, function.line);
        case F_SCMP:
            sScmp(stack, function.cmp_type, function.line);
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
            io::printfn("[ERROR] FunctionType doesnt exist or is not implemented (Line %d)", function.line);
            _exit(RUNTIME_OTHER_ERROR)!!;
    }
    return "!"; // this means stay in the same block
}

// execute a block
fn String exec_block(List{Node} *stack, Program *program, HashMap{String, Node} *registers, Block* block) {
    usz i = 0;
    while (i < block.functions.len()) {
        String next_block = eval(stack, block.functions.get_ref(i), registers);
        if (next_block != "!") return next_block;
        ++i;
    }
    return "."; // . means execution finished
}

// execute program
fn void exec(List{Node} *stack, Program *program, HashMap{String, Node} *registers, String block, String lastBlock) {
    Block* current_block = program.blocks.get_ref(block)!!;
    String next_block = "none";
    while (next_block != ".") {
        next_block = exec_block(stack, program, registers, current_block);
        if (next_block == ".") {
            break;
        }
        current_block = program.blocks.get_ref(next_block)!!;
    }
    io::printn("[INFO] Execution finished");
}

fn void add_block_function(Block *block, Function f) {
    block.functions.push(f);
}

fn Block init_block() {
    Block block = {};
    block.last_line = 0;
    return block;
}

fn void add_block_to_program(Program *program, Block block, String b_name) {
    program.blocks.set(b_name, block);
}

// helper functions for create_from_file()

fn bool is_whitespace(String token) {
    foreach (c: token) {
        if (c != ' ') return false;
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
    TokenType token_type;
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

// all of these should be self explanatory
fn bool is_keyword(String token) {
    foreach (keyword: keywords) {
        if (token == keyword) return true;
    }
    return false;
}

String numeric = "1234567890-.";

fn bool is_numeric(char c) {
    if (string::char_in_set(c, numeric)) return true;
    return false;
}

fn bool is_integer(String token) {
    foreach (idx, c: token) {
        switch {
            case c == '-': if (idx != 0) return false;
            case !is_numeric(c) || c == '.': return false;
        }
    }
    return true;
}

fn bool is_float(String token) {
    int dot_count = 0;
    foreach (idx, c: token) {
        switch {
            case !is_numeric(c): return false;
            case c == '.' && idx == 0: return false;
            case c == '.' && dot_count == 1: return false;
            case c == '.': dot_count += 1;
        }
    }
    return true;
}

String puncts = ";:!.";

fn bool is_punct(String token) {
    if (token.len == 1 && string::char_in_set(token[0], puncts)) {
        return true;
    }
    return false;
}

fn bool is_boolean(String token) {
    foreach (block: booleans) {
        if (token == block) {
            return true;
        }
    }
    return false;
}

fn void error_msg(String expected, Token token) {
    io::printf("[ERROR] Expected `%s`, got ", expected);
    io::print(token.token_type);
    io::print(": ");
    io::print(token.value);
    io::printfn(" in line %d", token.line);
    _exit(UNEXPECTED_TOKEN)!!;
}

// create a Program struct containing blocks
// which can then get executed
fn Program create_from_file(String file_path, bool debug) {
    String entire_file = (String)file::load_temp(file_path)!!;
    String[] lines = entire_file.split(mem, "\n");
    List{String} tokenstrings;
    List{usz} indices;
    foreach (i, line: lines) {
        String[] line_tokens = line.split(mem, " ");
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
                        switch {
                            case (token.ends_with(";")):
                                tokenstrings.push(token.strip_end(";"));
                                indices.push(i+1);
                                tokenstrings.push(";");
                                indices.push(i+1);
                            case (token.ends_with(":")):
                                tokenstrings.push(token.strip_end(":"));
                                indices.push(i+1);
                                tokenstrings.push(":");
                                indices.push(i+1);
                            default:
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

    List{Token} tokens;
    foreach (i, tokenstring: tokenstrings) {
        switch {
            case (is_keyword(tokenstring)):
                tokens.push({
                    .token_type = KEYWORD,
                    .value = tokenstring,
                    .line = indices.get(i)
                });
            case (is_integer(tokenstring)):
                tokens.push({
                    .token_type = INTEGER,
                    .value = tokenstring.strip("_"),
                    .line = indices.get(i)
                });
            case (tokenstring.starts_with("\"")):
                tokens.push({
                    .token_type = STRING,
                    .value = tokenstring.strip("\"").strip_end("\""),
                    .line = indices.get(i)
                });
            case (is_float(tokenstring)):
                tokens.push({
                    .token_type = FLOAT,
                    .value = tokenstring,
                    .line = indices.get(i)
                });
            case (is_punct(tokenstring)):
                tokens.push({
                    .token_type = PUNCT,
                    .value = tokenstring,
                    .line = indices.get(i)
                });
            case (is_boolean(tokenstring)):
                tokens.push({
                    .token_type = BOOL,
                    .value = tokenstring,
                    .line = indices.get(i)
                });
            default:
                tokens.push({
                    .token_type = SYMBOL,
                    .value = tokenstring,
                    .line = indices.get(i)
                });
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

    Program program = {};
    usz token_index = 0;

    switch {
        case (tokens.len() == 0):
            io::print("File is empty.");
            _exit(EMPTY_FILE)!!;
        case (tokens[token_index].token_type != SYMBOL):
            io::print("[ERROR] File needs to start with a block");
            _exit(FILE_DOESNT_START_WITH_BLOCK)!!;
    }

    while (token_index < tokens.len()) {
        if (tokens[token_index].token_type == SYMBOL) {
            Block block;
            block.last_line = 0;
            String block_name = tokens[token_index].value;

            token_index += 1;

            switch {
                case (tokens[token_index].token_type != PUNCT): // expect {
                    error_msg(":", tokens[token_index]);
                case (tokens[token_index].value != ":"):
                    error_msg(":", tokens[token_index]);
            }

            token_index += 1;

            while (token_index < tokens.len() && tokens[token_index + 1].value != ":") {
                if (tokens[token_index].token_type != KEYWORD) {
                    error_msg("keyword", tokens[token_index]);
                }
                switch (tokens[token_index].value) {
                    case ("push"):
                        token_index += 1;
                        switch (tokens[token_index].token_type) {
                            case STRING:
                                add_block_function(&block, {
                                    .function_type = F_PUSH,
                                    .operand = {
                                        .node_type = NodeType.STRING,
                                        .value.v_string = tokens[token_index].value
                                    },
                                    .line = tokens[token_index].line
                                });
                            case BOOL:
                                bool val;
                                if (tokens[token_index].value == "true") {
                                    val = true;
                                } else {
                                    val = false;
                                }
                                add_block_function(&block, {
                                    .function_type = F_PUSH,
                                    .operand = {
                                        .node_type = NodeType.BOOL,
                                        .value.v_bool = val},
                                    .line = tokens[token_index].line
                                });
                            case INTEGER:
                                add_block_function(&block, {
                                    .function_type = F_PUSH,
                                    .operand = {
                                        .node_type = NodeType.INT,
                                        .value.v_int = tokens[token_index].value.to_int()!!
                                    },
                                    .line = tokens[token_index].line
                                });
                            case FLOAT:
                                add_block_function(&block, {
                                    .function_type = F_PUSH,
                                    .operand = {
                                        .node_type = NodeType.FLOAT,
                                        .value.v_float = tokens[token_index].value.to_float()!!
                                    },
                                    .line = tokens[token_index].line
                                });
                            default:
                                error_msg("String, bool, int or float", tokens[token_index]);
                        }
                    case ("print"):
                        add_block_function(&block, {
                            .function_type = F_PRINT,
                            .line = tokens[token_index].line
                        });
                    case ("swp"):
                        add_block_function(&block, {
                            .function_type = F_SWP,
                            .line = tokens[token_index].line
                        });
                    case ("dup"):
                        add_block_function(&block, {
                            .function_type = F_DUP,
                            .line = tokens[token_index].line
                        });
                    case ("icmp"):
                        token_index += 1;
                        if (tokens[token_index].token_type != KEYWORD) {
                            error_msg("comparison type", tokens[token_index]);
                        }
                        switch (tokens[token_index].value) {
                            case ("eq"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = EQ,
                                    .line = tokens[token_index].line
                                });
                            case ("ne"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = NE,
                                    .line = tokens[token_index].line
                                });
                            case ("lt"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = LT,
                                    .line = tokens[token_index].line
                                });
                            case ("le"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = LE,
                                    .line = tokens[token_index].line
                                });
                            case ("gt"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = GT,
                                    .line = tokens[token_index].line
                                });
                            case ("ge"):
                                add_block_function(&block, {
                                    .function_type = F_ICMP,
                                    .cmp_type = GE,
                                    .line = tokens[token_index].line
                                });
                            default:
                                error_msg("comparison type", tokens[token_index]);
                        }
                    case ("callcon"):
                        token_index += 1;
                        if (tokens[token_index].token_type != SYMBOL) {
                            error_msg("block name", tokens[token_index]);
                        }
                        add_block_function(&block, {
                            .function_type = F_CALLCON,
                            .operand = {
                                .node_type = NodeType.STRING,
                                .value.v_string = tokens[token_index].value
                            },
                            .line = tokens[token_index].line
                        });
                    case ("call"):
                        token_index += 1;
                        if (tokens[token_index].token_type != SYMBOL) {
                            error_msg("block name", tokens[token_index]);
                        }
                        add_block_function(&block, {
                            .function_type = F_CALL,
                            .operand = {
                                .node_type = NodeType.STRING,
                                .value.v_string = tokens[token_index].value
                            }, .line = tokens[token_index].line
                        });
                    case ("prstk"):
                        add_block_function(&block, {
                            .function_type = F_PRSTK,
                            .line = tokens[token_index].line
                        });
                    case ("pop"):
                        add_block_function(&block, {
                            .function_type = F_POP,
                            .line = tokens[token_index].line
                        });
                    case ("isub"):
                        add_block_function(&block, {
                            .function_type = F_ISUB,
                            .line = tokens[token_index].line
                        });
                    case ("addi"):
                        add_block_function(&block, {
                            .function_type = F_ADDI,
                            .line = tokens[token_index].line
                        });
                    case ("ldx"):
                        add_block_function(&block, {
                            .function_type = F_LDX,
                            .line = tokens[token_index].line
                        });
                    case ("ldxnp"):
                        add_block_function(&block, {
                            .function_type = F_LDXNP,
                            .line = tokens[token_index].line
                        });
                    case ("ldynp"):
                        add_block_function(&block, {
                            .function_type = F_LDYNP,
                            .line = tokens[token_index].line
                        });
                    case ("ldy"):
                        add_block_function(&block, {
                            .function_type = F_LDY,
                            .line = tokens[token_index].line
                        });
                    case ("stx"):
                        add_block_function(&block, {
                            .function_type = F_STX,
                            .line = tokens[token_index].line
                        });
                    case ("sty"):
                        add_block_function(&block, {
                            .function_type = F_STY,
                            .line = tokens[token_index].line
                        });
                    case ("txy"):
                        add_block_function(&block, {
                            .function_type = F_TXY,
                            .line = tokens[token_index].line
                        });
                    case ("tyx"):
                        add_block_function(&block, {
                            .function_type = F_TYX,
                            .line = tokens[token_index].line
                        });
                    case ("rdf"):
                        add_block_function(&block, {
                            .function_type = F_RDF,
                            .line = tokens[token_index].line
                        });
                    case ("wtf"):
                        add_block_function(&block, {
                            .function_type = F_WTF,
                            .line = tokens[token_index].line
                        });
                    case ("atf"):
                        add_block_function(&block, {
                            .function_type = F_ATF,
                            .line = tokens[token_index].line
                        });
                    case ("chkerr"):
                        add_block_function(&block, {
                            .function_type = F_CHKERR,
                            .line = tokens[token_index].line
                        });
                    case ("ssplt"):
                        add_block_function(&block, {
                            .function_type = F_SSPLT,
                            .line = tokens[token_index].line
                        });
                    case ("preg"):
                        add_block_function(&block, {
                            .function_type = F_PREG,
                            .line = tokens[token_index].line
                        });
                    default:
                        io::printfn("%s not implemented or does not exist (Line %d)", tokens[token_index].value, tokens[token_index].line);
                        _exit(NOT_IMPLEMENTED)!!;
                }
                token_index += 1;

                switch {
                    case tokens[token_index].token_type != PUNCT:
                        error_msg(";", tokens[token_index]);
                    case tokens[token_index].value != ";":
                        error_msg(";", tokens[token_index]);
                }
                token_index += 1;
            }
            if (debug) {
                io::printn("-------- Functions --------");
                foreach (f: block.functions) {
                    io::printf("    %s: ", block_name);
                    io::printn(f);
                }
                io::printn("-------- Functions --------\n");
            }
            add_block_to_program(&program, block, block_name);
        }
    }
    return program;
}

fn int main(String[] args) {
    bool debug = false;

    switch {
        case args.len < 2:
            io::print("[ERROR] You need to supply a file.");
            return 1;
        case args.len > 2 && args[2] == "debug":
            debug = true; // to print debug info in create_from_file
    }

    // initialize stuff
    String file_path = args[1];
    Program program = create_from_file(file_path, debug);
    List{Node} stack;
    stack.init(mem, initial_capacity: 1024);
    HashMap{String, Node} registers;
    registers.set("x", {.node_type = NodeType.INT, .value.v_int = 0});
    registers.set("y", {.node_type = NodeType.INT, .value.v_int = 0});

    switch {
        case !program.blocks.has_key("main"):
            io::print("[ERROR] No main block.");
            _exit(NO_MAIN_BLOCK)!!;
        case debug:
            mem::@report_heap_allocs_in_scope() {
            exec(&stack, &program, &registers, "main", "none");
            io::printn("\n----- Debug -----");
            };
        default:
            exec(&stack, &program, &registers, "main", "none");
    }
    return 0;
}
