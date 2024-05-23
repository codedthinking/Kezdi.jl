using Logging
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, Number, LineNumberNode, QuoteNode}
    level::Int64
    tree_position::Int64
end

struct Where
    condition::Tuple
end

struct Options
    options::Tuple
end

struct Command 
    command::Symbol
    arguments::Tuple
    condition::Where
    options::Options
end

SYMBOLS = [:(==), :<, :>, :!=, :<=, :>=]

function extract_args(arg; depth::Int64=0, position::Int64)::Node
    if isa(arg, Expr)
        return Node(arg.head, arg, depth, position)
    else
        return Node(typeof(arg), arg, depth, position)
    end
end

function parse(exprs::Tuple)::Vector{Node}
    args = Vector{Node}()
    for (i,expr) in enumerate(exprs)
        if isa(expr, Expr)
            push!(args, parse_expr(expr; depth=1)...)
        else
            push!(args, extract_args(expr;position=i))
        end
    end
    return args
end

function parse_expr(expr::Expr; depth::Int64=0)::Vector{Node}
    args = Vector{Node}()
    if expr.args != []
        for (i,arg) in enumerate(expr.args)
            if arg == expr.args[1]
                push!(args, Node(expr.head, arg, depth, i))
            end
            if isa(arg, Expr)
                push!(args, parse_expr(arg; depth=depth+1)...)
            else
                push!(args, extract_args(arg; depth=depth, position=i))
            end
        end
    end
    return args
end

function switch_tuple(args::Vector{Node})::Vector{Node}
    for (i,arg) in enumerate(args)
        if arg.type == :tuple && arg.content == args[i+1].content
            args[i] = args[i+1]
            args[i+1] = arg
        end
    end
    return args
end

function construct_calls(nodes::Vector{Node})::Vector{Union{Expr, Symbol, Int64}}
    if isempty(nodes)
        return Vector{Union{Expr, Symbol, Int64}}()
    end
    syntax_levels = unique([node.level for node in nodes])
    calls = []
    in_call = false
    prev_pos = 0
    for level in syntax_levels
        @debug"Processing level $level"
        call_level = []
        function_call = nothing
        call_args = [node for node in nodes if node.level == level]
        for arg in call_args
            @debug"Processing argument $arg"
            if in_call && arg.tree_position != prev_pos + 1
                in_call = false
                @debug"Stepping out of function call at $arg"
                function_call = Expr(call_level[1].type, [arg.content for arg in call_level[2:end]]...)
                @debug"Adding function call to calls $function_call"
                push!(calls, function_call)
                call_level = []
                prev_pos = 0
            end
            if in_call && arg == last(call_args)
                in_call = false
                push!(call_level, arg)
                @debug"Stepping out of function call at $arg"
                function_call = Expr(call_level[1].type, [arg.content for arg in call_level[2:end]]...)
                @debug"Adding function call to calls $function_call"
                push!(calls, function_call)
                call_level = []
                prev_pos = 0
                continue
            end
            if arg.type == :call
                in_call = true
                @debug"Stepping into function call at $arg"
                push!(call_level, arg)
                continue
            end
            if in_call
                @debug"Adding $arg to function call"
                push!(call_level, arg)
                prev_pos = arg.tree_position
                continue
            end
            if !in_call
                @debug"Adding argument to calls $arg"
                push!(calls, arg.content)
            end
        end
    end
    @debug"calls are $calls"
    return calls
end

function transition(state::Int64,arg::Node)
    ## from command to condition
    if arg.type == :macrocall && arg.content == Symbol("@if") && state == 1
        state = 2
        @debug"Stepping out of command at $arg"
        @debug"Stepping into condition at $arg"
    end
    ## from command to option
    if state == 1 && arg.type == :tuple
        state = 3
        @debug"Stepping out of command at $arg"
        @debug"Stepping into options at $arg"
    end
    ## from condition to option
    if state == 2 && arg.type == :tuple && !in(arg.content, SYMBOLS) 
        state = 3
        @debug"Stepping out of condition at $arg"
        @debug"Stepping into options at $arg"
    end
    return state
end

function transpile(exprs::Tuple, command::Symbol)::Command
    ast = parse(exprs)
    ast = switch_tuple(ast)
    @info "AST is $ast"
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = Vector{Node}()
    state = 1
    @debug"Starting in command"
    for arg in ast
        state = transition(state, arg)
        if state == 1
            if arg.type in [:call, Symbol, Int64]
                push!(arguments, arg)
            end
        end
        if state == 2
            if arg.type in [:call, Symbol, Int64] && arg.content != Symbol("@if")
                push!(condition, arg)
            end
        end
        if state == 3
            if arg.type in [:call, :macrocall, Symbol, Int64]
                push!(options, arg)
            end
        end
    end
    @debug"Arguments are $arguments"
    @debug"Condition is $condition"
    @debug"Options are $options"
    arguments = construct_calls(arguments)
    condition = construct_calls(condition)
    options = construct_calls(options)
    return Command(command, Tuple(arguments), Where(Tuple(condition)), Options(Tuple(options)))
end

macro dummy(exprs...)
    command = Symbol("@keep")
    cmd = transpile(exprs, command)
    return cmd
end

if abspath(PROGRAM_FILE) == @__FILE__
    cmd = @dummy a b @if d == 1 && c == 0, cluster(z) whatever drop(x) peek pipe(y,x)
    println(cmd)
end