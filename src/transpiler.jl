using Logging
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

include("structs.jl")

SYMBOLS = [:(==), :<, :>, :!=, :<=, :>=]

function extract_args(arg; depth::Int64=0, position::Int64=1)::Node
    if isa(arg, Expr)
        if arg.head == :tuple
            return Node(arg.head, arg.args, depth, position)
        end
        return Node(arg.head, arg, depth, position)
    end
    return Node(typeof(arg), arg, depth, position)
end

function parse(exprs::Tuple)::Vector{Node}
    args = Vector{Node}()
    for (i,expr) in enumerate(exprs)
        if isa(expr, Expr)
            if expr.head == :macrocall
                push!(args, parse_expr(expr; depth=1)...)
            else
                push!(args, extract_args(expr; depth=1, position=i))
            end
        else
            push!(args, extract_args(expr;position=i))
        end
    end
    return args
end

function parse_expr(expr::Expr; depth::Int64=0)::Vector{Node}
    args = Vector{Node}()
    if isempty(expr.args)
        return args
    end

    for (i,arg) in enumerate(expr.args)
        if arg == expr.args[1]
            push!(args, Node(expr.head, expr.args, depth, i))
        end
        if isa(arg, Expr)
            push!(args, Node(arg.head, arg.args, depth+1, i))
        else
            push!(args, extract_args(arg; depth=depth, position=i))
        end
    end
    return args
end

function construct_call(node::Node)
    if node.type == :call || node.type in [:&&, :||]
        if typeof(node.content) == Expr
            return node.content
        else
            return Expr(node.type, node.content...)
        end
    end
    return node.content
end

function transition(state::Int64,arg::Node)::Int64
    ## from command to condition
    if arg.content == Symbol("@if") && state == 1
        state = 2
        @debug "Stepping out of command at $arg"
        @debug "Stepping into condition at $arg"
    end
    ## from command to option
    if state == 1 && arg.type == :tuple
        state = 3
        @debug "Stepping out of command at $arg"
        @debug "Stepping into options at $arg"
    end
    ## from condition to option
    if state == 2 && arg.type == :tuple && !in(arg.content, SYMBOLS) 
        state = 3
        @debug "Stepping out of condition at $arg"
        @debug "Stepping into options at $arg"
    end
    return state
end

function transpile(exprs::Tuple, command::Symbol)::Command
    ast = parse(exprs)
    @info "AST is $ast"
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = nothing
    state = 1
    @debug "Starting in command"
    for arg in ast
        if state == 1
            if arg.type in [:call, Symbol, Int64, :(=)] && arg.content != Symbol("@if")
                push!(arguments, arg)
            end
            if arg.type == :tuple
                push!(arguments, extract_args(arg.content[1]))
                push!(options, extract_args(arg.content[2]))
            end
        end
        if state == 2
            if arg.type in [:call, Symbol, Int64, :&&, :||]
                condition = arg
            end
            if arg.type == :tuple
                condition = extract_args(arg.content[1])
                push!(options, extract_args(arg.content[2]))
            end
        end
        if state == 3
            if arg.type in [:call, :macrocall, Symbol, Int64]
                push!(options, arg)
            end
        end
        state = transition(state, arg)
    end
    @debug "Arguments are $arguments"
    @debug "Condition is $condition"
    @debug "Options are $options"
    arguments = Tuple(construct_call(arg) for arg in arguments)
    options = Tuple(construct_call(opt) for opt in options)
    if isa(condition, Node)
        condition = construct_call(condition)
    end
    return Command(command, arguments, condition, options)
end

macro dummy(exprs...)
    command = Symbol("@dummy")
    cmd = transpile(exprs, command)
    return cmd
end

if abspath(PROGRAM_FILE) == @__FILE__
    cmd = @dummy x @if x < 0 && y > 0 #a b @if d == 1 && c == 0, cluster(z) whatever drop(x) peek pipe(y,x)
    println(cmd)
end