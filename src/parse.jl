function extract_args(arg; position::Int64=1)::Node
    if arg isa Expr
        if arg.head == :tuple
            return Node(arg.head, arg.args, position)
        end
        return Node(arg.head, arg, position)
    end
    return Node(typeof(arg), arg, position)
end

function scan(exprs::Tuple)::Vector{Node}
    args = Vector{Node}()
    for (i, expr) in enumerate(exprs)
        if expr isa Expr && expr.head == :macrocall
            push!(args, scan(expr)...)
        else
            push!(args, extract_args(expr; position=i))
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
            push!(args, Node(expr.head, expr.args, i))
        end
        if arg isa Expr
            push!(args, Node(arg.head, arg.args, i))
        else
            push!(args, extract_args(arg; position=i))
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

function parse(exprs::Tuple, command::Symbol)::Command
    ast = scan(exprs)
    @debug "AST is $ast"
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = nothing
    state = 1
    @debug "Starting in command"
    for arg in ast
        @info "In state $state, argument is $arg"
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