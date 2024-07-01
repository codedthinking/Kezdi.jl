global_logger(Logging.ConsoleLogger(stderr, Logging.Info))
function extract_args(arg)::Node
    if arg isa Expr
        if arg.head == :tuple
            return Node(arg.head, arg.args)
        end
        return Node(arg.head, arg)
    end
    return Node(typeof(arg), arg)
end

function scan(exprs::Tuple)::Vector{Node}
    args = Vector{Node}()
    for (i, expr) in enumerate(exprs)
        if expr isa Expr && expr.head == :macrocall
            push!(args, scan(expr)...)
        else
            push!(args, extract_args(expr))
        end
    end
    return args
end

function scan(expr::Expr)::Vector{Node}
    args = Vector{Node}()
    if isempty(expr.args)
        return args
    end

    for (i, arg) in enumerate(expr.args)
        if arg == expr.args[1]
            push!(args, Node(expr.head, expr.args))
        end
        if arg isa Expr
            push!(args, Node(arg.head, arg.args))
        else
            push!(args, extract_args(arg))
        end
    end
    return args
end

function construct_call(node::Node)
    if !(node.type in [:&&, :||, :call])
        return node.content
    end

    if node.type in [:&&, :||] && typeof(node.content) != Expr
        return Expr(Symbol("." * String(node.type)), replace_logical_operators.(node.content)...)
    end
    
    if typeof(node.content) == Expr
        if node.type in [:&&, :||]
            return Expr(Symbol("." * String(node.type)), node.content.args...)
        end
        return node.content
    end

    return Expr(node.type, node.content...)
end

function replace_logical_operators(args)
    if args in [:&&, :||]
        return Symbol("." * String(args))
    end
    return args
end

function replace_logical_operators(args::Expr)::Expr
    if args.head in [:&&, :||]
        return Expr(Symbol("." * String(args.head)), replace_logical_operators.(args.args)...)
    end
    return args
end

function transition(state::Int64, arg::Node)::Int64
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
    if state == 2 && arg.type == :tuple && !in(arg.content, OPERATORS) 
        state = 3
        @debug "Stepping out of condition at $arg"
        @debug "Stepping into options at $arg"
    end
    return state
end

function isassignment(node::Node)
    return node.type == :(=)
end

function splitassignment(node::Node)
    if isassignment(node)
        expr = node.content
        return (expr.args[1], expr.args[2])
    end
end

function parse(exprs::Tuple, command::Symbol)::Command
    ast = scan(exprs)
    @debug "AST is $ast"
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = nothing
    state = 1
    @debug "Starting in command"
    for (i, arg) in enumerate(ast)
        @debug "In state $state, argument number $i is $arg"
        if isassignment(arg)
            LHS, RHS = splitassignment(arg)
            next_arg = extract_args(RHS)
            if next_arg.type == :tuple
                push!(arguments, extract_args(:($LHS = $(next_arg.content[1]))))
                push!(options, extract_args(next_arg.content[2]))
                state = transition(state, next_arg)
                continue
            end
        end
        if state == 1
            if arg.type == :tuple
                push!(arguments, extract_args(arg.content[1]))
                push!(options, extract_args(arg.content[2]))
            elseif arg.type != :macrocall && arg.content != Symbol("@if")
                push!(arguments, arg)
            end
        end
        if state == 2
            if arg.type == :tuple
                condition = extract_args(arg.content[1])
                push!(options, extract_args(arg.content[2]))
            else
                condition = arg
            end
        end
        if state == 3
            push!(options, arg)
        end
        state = transition(state, arg)
    end
    @debug "Arguments are $arguments"
    @debug "Condition is $condition"
    @debug "Options are $options"
    arguments = Tuple(construct_call(arg) for arg in arguments)
    options = Tuple(construct_call(opt) for opt in options)
    if condition isa Node
        condition = construct_call(condition)
    end
    return Command(command, arguments, condition, options)
end

parse(exprs::Tuple) = x::Symbol -> parse(exprs, x)