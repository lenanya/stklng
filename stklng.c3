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
	F_RETURN, // return to the last block
	F_SWP, // swap stack[-1] with stack[-2]
	F_DUP, // duplicate stack[-1]
    F_LDX,
    F_STX,
    F_LDY,
    F_STY,
    F_TYX,
    F_TXY,
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
}

struct Node {
    NodeType nodeType;
    any value;
}

struct Block {
    usz last_line;
    List(<Function>) functions;
}

struct Function {
    FunctionType functionType;
    Node operand;
    CmpType cmpType;
}

struct Program {
    Map(<String, Block>) blocks;
}

fn void sPrstk(List(<Node>) *stack) {
    io::printn("----     Stack    ----");
    foreach (i, node: stack) {
        switch (node.nodeType) {
            case NodeType.INT: 
                io::printfn("%d Int: %d", i, *(int*)node.value);
            case NodeType.STRING: 
                io::printfn("%d String: \"%s\"", i, *(String*)node.value);
            case NodeType.BOOL:
                String booleanValue = "false"; 
                if (*(bool*)node.value) {
                    booleanValue = "true";
                }
                io::printfn("%d Boolean: %s", i, booleanValue);
            case NodeType.FLOAT:
                io::printfn("%d Float: %f", i, *(float*)node.value);
            default:
                io::printf("%d Unknown Type: ", i); // TODO: fix
                io::printn(node.value);
        }
    }
    io::printn("---- End of Stack ----");
}

fn void sPush(List(<Node>) *stack, Node node) {
    stack.push(node);
}

fn void sPopMany(List(<Node>) *stack, uint amount) {
    for (uint i = 0; i < amount; ++i) {
        stack.pop()!!;
    }
}

macro sPop(stack) {
    sPopMany(stack, 1);
}

fn void sAddi(List(<Node>) *stack, ) {
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printn("[ERROR] addi requires 2 integers on the stack");
        libc::exit(1);
    }
    int addend = *(int*)stack.last().value!!;
    sPop(stack);
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printn("[ERROR] addi requires 2 integers on the stack");
        libc::exit(1);
    }
    int addend2 = *(int*)stack.last().value!!;
    sPop(stack);
    sPush(stack, {.nodeType = NodeType.INT, .value = mem::@clone(addend + addend2)});
}

fn void sAddf(List(<Node>) *stack, ) {
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] addf requires 2 floats on the stack");
        libc::exit(1);
    }
    float addend = *(float*)stack.last().value!!;
    sPop(stack);
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] addf requires 2 floats on the stack");
        libc::exit(1);
    }
    float addend2 = *(float*)stack.last().value!!;
    sPop(stack);
    sPush(stack, {.nodeType = NodeType.FLOAT, .value = mem::@clone(addend + addend2)});
}

fn void sScat(List(<Node>) *stack, ) {
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printn("[ERROR] scat requires 2 strings on the stack");
        libc::exit(1);
    }
    String s1 = *(String*)stack.last().value!!;
    sPop(stack);
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printn("[ERROR] scat requires 2 strings on the stack");
        libc::exit(1);
    }
    String s2 = *(String*)stack.last().value!!;
    sPop(stack);
    String final = s1.tconcat(s2);
    sPush(stack, {.nodeType = NodeType.STRING, .value = mem::@clone(final)});
}

fn void sIcmp(List(<Node>) *stack, CmpType cmp) {
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printn("[ERROR] icmp requires 2 integers on the stack");
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.INT) {
        io::printn("[ERROR] icmp requires 2 integers on the stack");
        libc::exit(1);
    }
    int i1 = *(int*)stack.last().value!!;
    int i2 = *(int*)stack.get(stack.len() - 2).value;
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
    sPush(stack, {.nodeType = NodeType.BOOL, .value = mem::@clone(result)});
}

fn void sFcmp(List(<Node>) *stack, CmpType cmp) {
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] fcmp requires 2 floats on the stack");
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] fcmp requires 2 floats on the stack");
        libc::exit(1);
    }
    float f1 = *(float*)stack.last().value!!;
    float f2 = *(float*)stack.get(stack.len() - 2).value;
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
    sPush(stack, {.nodeType = NodeType.BOOL, .value = mem::@clone(result)});
}

fn void sScmp(List(<Node>) *stack, CmpType cmp) {
    if (stack.last()!!.nodeType != NodeType.STRING) {
        io::printn("[ERROR] scmp requires 2 Strings on the stack");
        libc::exit(1);
    }
    if (stack.get(stack.len() - 2).nodeType != NodeType.STRING) {
        io::printn("[ERROR] scmp requires 2 Strings on the stack");
        libc::exit(1);
    }
    String s1 = *(String*)stack.last().value!!;
    String s2 = *(String*)stack.get(stack.len() - 1).value;
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
    sPush(stack, {.nodeType = NodeType.BOOL, .value = mem::@clone(result)});
}

fn void sIsub(List(<Node>) *stack, ) {
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printn("[ERROR] addi requires 2 integers on the stack");
        libc::exit(1);
    }
    int minuend = *(int*)stack.last().value!!;
    sPop(stack);
    if (stack.last()!!.nodeType != NodeType.INT) {
        io::printn("[ERROR] addi requires 2 integers on the stack");
        libc::exit(1);
    }
    int subtrahend = *(int*)stack.last().value!!;
    sPop(stack);
    sPush(stack, {.nodeType = NodeType.INT, .value = mem::@clone(minuend - subtrahend)});
}

fn void sFsub(List(<Node>) *stack, ) {
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] addf requires 2 floats on the stack");
        libc::exit(1);
    }
    float minuend = *(float*)stack.last().value!!;
    sPop(stack);
    if (stack.last()!!.nodeType != NodeType.FLOAT) {
        io::printn("[ERROR] addf requires 2 floats on the stack");
        libc::exit(1);
    }
    float subtrahend = *(float*)stack.last().value!!;
    sPop(stack);
    sPush(stack, {.nodeType = NodeType.FLOAT, .value = mem::@clone(minuend - subtrahend)});
}

fn void sSwp(List(<Node>) *stack) {
    stack.swap(stack.len() - 1, stack.len() - 2);
}

fn void sDup(List(<Node>) *stack) {
    Node node = stack.last()!!;
    sPush(stack, node);
}

fn void sPrint(List(<Node>) *stack) {
    Node node = stack.last()!!;
    switch (node.nodeType) {
            case NodeType.INT: 
                io::printn(*(int*)node.value);
            case NodeType.STRING: 
                io::printn(*(String*)node.value);
            case NodeType.BOOL:
                String booleanValue = "false"; 
                if (*(bool*)node.value) {
                    booleanValue = "true";
                }
                io::printn(booleanValue);
            case NodeType.FLOAT:
                io::printn(*(float*)node.value);
            default:
                io::print("Unknown Type: "); // TODO: fix
                io::printn(node.value);
        }
}

fn void sLdx(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = stack.last()!!;
    registers.set("x", node);
}

fn void sStx(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = registers.get("x")!!;
    sPush(stack, node);
}

fn void sLdy(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = stack.last()!!;
    registers.set("y", node);
}

fn void sSty(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = registers.get("y")!!;
    sPush(stack, node);
}

fn void sTxy(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = registers.get("x")!!;
    registers.set("y", node);
}

fn void sTyx(List(<Node>) *stack, Map(<String, Node>) *registers) {
    Node node = registers.get("y")!!;
    registers.set("x", node);
}
 
fn String eval(List(<Node>) *stack, Function function, Map(<String, Node>) *registers) {
    switch (function.functionType) {
        case F_PUSH:
            sPush(stack, function.operand);
        case F_POP:     
            sPop(stack);
        case F_ADDI:
            sAddi(stack);
        case F_CALL:
            return *(String*)function.operand.value;
        case F_PRSTK: 
            sPrstk(stack);
        case F_RETURN:
            return "return";
        case F_CALLCON:
            if (*(bool*)stack.last().value!!) {
                return *(String*)function.operand.value;
            }
        case F_SWP:
            sSwp(stack);
        case F_DUP:
            sDup(stack);
        case F_ISUB: 
            sIsub(stack);
        case F_FSUB:
            sFsub(stack);
        case F_ADDF:
            sAddf(stack);
        case F_SCAT:
            sScat(stack);
        case F_ICMP:
            sIcmp(stack, function.cmpType);
        case F_FCMP:
            sFcmp(stack, function.cmpType);
        case F_SCMP:
            sScmp(stack, function.cmpType);
        case F_PRINT:
            sPrint(stack);
        case F_LDX:
            sLdx(stack, registers);
        case F_LDY:
            sLdy(stack, registers);
        case F_STX:
            sStx(stack, registers);
        case F_STY:
            sSty(stack, registers);
        case F_TYX:
            sTyx(stack, registers);
        case F_TXY:
            sTxy(stack, registers);
        default:
            unreachable("doesnt exist or not implemented");

    }
    return "!";
}

fn void exec(List(<Node>) *stack, Program program, Map(<String, Node>) *registers, String block, String lastBlock) {
    Block current_block = program.blocks.get(block)!!;
    usz i = current_block.last_line;
    while (i < current_block.functions.len()) {
        current_block.last_line = i + 1;
        String next_block = eval(stack, current_block.functions[i], registers);
        if (next_block != "!") {
            if (next_block == "return") {
                if (lastBlock == "none") {
                    io::printn("[ERROR] Can't return from main");
                    libc::exit(1);
                }
                current_block.last_line = 0;
                program.blocks.set(block, current_block);
                i = current_block.functions.len() + 1;
                exec(stack, program, registers, lastBlock, block);
            } else {
                current_block.last_line = 0;
                program.blocks.set(block, current_block);
                i = current_block.functions.len() + 1;
                exec(stack, program, registers, next_block, block);
            }
        }
        ++i;
    }
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
    "return",
    "ldx",
    "ldy",
    "stx",
    "sty",
    "txy",
    "tyx",
    "swp",
    "dup",
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
};

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
    io::printf("[ERROR] Expected %s, got ", expected);
    io::print(token.tokenType);
    io::print(": ");
    io::printn(token.value);
    libc::exit(1);
}

fn Program createFromFile(String filePath, bool debug) {
    String entireFile = (String)file::load_temp(filePath)!!;
    String[] lines = entireFile.split("\n");
    List(<String>) tokenstrings;
    foreach (line: lines) {
        String[] line_tokens = line.split(" ");
        String string_literal = "";
        bool in_string_literal = false;
        foreach (token: line_tokens) {
            if (!in_string_literal) {
                if (token.starts_with("//")) {
                    break; // comments just dont get put in the tokens
                }
                if (token.starts_with("\"")) {
                    in_string_literal = true;
                    if (token.ends_with("\";")) {
                        string_literal = token.strip_end(";");
                        in_string_literal = false;
                        tokenstrings.push(string_literal);
                        tokenstrings.push(";");
                    }
                    string_literal = token;
                } else {
                    if (!is_whitespace(token)) {
                        if (token.ends_with(";")) {
                            tokenstrings.push(token.strip_end(";"));
                            tokenstrings.push(";");
                        } else if (token.ends_with(":")) {
                            tokenstrings.push(token.strip_end(":"));
                            tokenstrings.push(":");
                        } else {
                            tokenstrings.push(token);
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
                    tokenstrings.push(";");
                    in_string_literal = false;
                }
            }
        } 
    }

    List(<Token>) tokens;
    foreach (tokenstring: tokenstrings) {
        if (is_keyword(tokenstring)) {
            tokens.push({.tokenType = KEYWORD, .value = tokenstring});
        } else if (is_integer(tokenstring)) {
            tokens.push({.tokenType = INTEGER, .value = tokenstring.strip("_")});
        } else if (tokenstring.starts_with("\"")) {
            tokens.push({.tokenType = STRING, .value = tokenstring.strip("\"").strip_end("\"")});
        } else if (is_float(tokenstring)) {
            tokens.push({.tokenType = FLOAT, .value = tokenstring});
        } else if (is_punct(tokenstring)) {
            tokens.push({.tokenType = PUNCT, .value = tokenstring});
        } else if (is_boolean(tokenstring)) {
            tokens.push({.tokenType = BOOL, .value = tokenstring});
        } else {
            tokens.push({.tokenType = SYMBOL, .value = tokenstring});
        }
    }
    if (debug) {
        foreach (token: tokens) {
            io::printn(token);
        }
    }

    Program p = {};
    usz tokenIndex = 0;
   
    if (tokens.len() == 0) {
        libc::exit(0);
    }
    if (tokens[tokenIndex].tokenType != SYMBOL) {
        io::printn("[ERROR] File needs to start with a block.");
        libc::exit(0);
    }
    while (tokenIndex < tokens.len()) {
        if (tokens[tokenIndex].tokenType == SYMBOL) {
            Block b;
            b.last_line = 0;
            String block_name = tokens[tokenIndex].value;

            tokenIndex += 1;

            if (tokens[tokenIndex].tokenType != PUNCT) {
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
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.STRING, .value = mem::@clone(tokens[tokenIndex].value)}});
                            case BOOL:
                                bool val;
                                if (tokens[tokenIndex].value == "true") {
                                    val = true;
                                } else {
                                    val = false;
                                }
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.BOOL, .value = mem::@clone(val)}});
                            case INTEGER:
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.INT, .value = mem::@clone(tokens[tokenIndex].value.to_int()!!)}});
                            case FLOAT:
                                add_block_function(&b, {.functionType = F_PUSH, .operand = {.nodeType = NodeType.FLOAT, .value = mem::@clone(tokens[tokenIndex].value.to_float()!!)}});
                            default:
                                error_msg("String, bool, int or float", tokens[tokenIndex]);
                        }
                    case ("print"):
                        add_block_function(&b, {.functionType = F_PRINT});
                    case ("swp"):
                        add_block_function(&b, {.functionType = F_SWP});
                    case ("dup"):
                        add_block_function(&b, {.functionType = F_DUP});
                    case ("icmp"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != KEYWORD) {
                            error_msg("comparison type", tokens[tokenIndex]);
                        }
                        switch (tokens[tokenIndex].value) {
                            case ("eq"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = EQ});
                            case ("ne"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = NE});
                            case ("lt"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = LT});
                            case ("le"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = LE});
                            case ("gt"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = GT});
                            case ("ge"):
                                add_block_function(&b, {.functionType = F_ICMP, .cmpType = GE});
                            default:
                                error_msg("comparison type", tokens[tokenIndex]);
                        }
                    case ("callcon"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != SYMBOL) {
                            error_msg("block name", tokens[tokenIndex]);
                        }
                        add_block_function(&b, {.functionType = F_CALLCON, .operand = {.nodeType = NodeType.STRING, .value = mem::@clone(tokens[tokenIndex].value)}});
                    case ("call"):
                        tokenIndex += 1;
                        if (tokens[tokenIndex].tokenType != SYMBOL) {
                            error_msg("block name", tokens[tokenIndex]);
                        }
                        add_block_function(&b, {.functionType = F_CALL, .operand = {.nodeType = NodeType.STRING, .value = mem::@clone(tokens[tokenIndex].value)}});
                    case ("prstk"):
                        add_block_function(&b, {.functionType = F_PRSTK});
                    case ("pop"):
                        add_block_function(&b, {.functionType = F_POP});
                    case ("isub"):
                        add_block_function(&b, {.functionType = F_ISUB});
                    case ("addi"):
                        add_block_function(&b, {.functionType = F_ADDI});
                    case ("return"):
                        add_block_function(&b, {.functionType = F_RETURN});
                    case ("ldx"):
                        add_block_function(&b, {.functionType = F_LDX});
                    case ("ldy"):
                        add_block_function(&b, {.functionType = F_LDY});
                    case ("stx"):
                        add_block_function(&b, {.functionType = F_STX});
                    case ("sty"):
                        add_block_function(&b, {.functionType = F_STY});
                    case ("txy"):
                        add_block_function(&b, {.functionType = F_TXY});
                    case ("tyx"):
                        add_block_function(&b, {.functionType = F_TYX});
                    default:
                        io::printfn("%s not implemented :(", tokens[tokenIndex].value);
                        libc::exit(1);
                }
                tokenIndex += 1;
                if (tokens[tokenIndex].tokenType != PUNCT) {
                    error_msg(";", tokens[tokenIndex]);
                }
                tokenIndex += 1;
            }
            if (debug) {
                foreach (f: b.functions) {
                    io::printf("%s: ", block_name);
                    io::printn(f);
                }
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
            debug = true;
        }
    }

    String filePath = args[1];
    Program p = createFromFile(filePath, debug);
    List(<Node>) stack;
    Map(<String, Node>) registers;
    registers.set("x", {.nodeType = NodeType.INT, .value = mem::@clone(0)});
    registers.set("y", {.nodeType = NodeType.INT, .value = mem::@clone(0)});
    if (!p.blocks.has_key("main")) {
        io::printn("[ERROR] No main block.");
        return 1;
    }

    exec(&stack, p, &registers, "main", "none");
    return 0;
}