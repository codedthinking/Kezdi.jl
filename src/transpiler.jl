using Logging
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

struct Node
    type::Union{Symbol, Type}
    content::Union{Expr, Symbol, Number, LineNumberNode, QuoteNode}
    level::Int64
    tree_position::Int64
end

struct Where
    condition::Expr
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


function construct_calls(nodes::Vector{Node})::Vector{Union{Expr, Symbol, Int64}}
    syntax_levels = unique([node.level for node in nodes])
    options = []
    in_option_call = false
    prev_pos = 0
    for level in syntax_levels
        @info "Processing level $level"
        option_level = []
        function_call = nothing
        option_args = [node for node in nodes if node.level == level]
        for arg in option_args
            @info "Processing argument $arg"
            if in_option_call && arg.tree_position != prev_pos + 1
                in_option_call = false
                @info "Stepping out of function call at $arg"
                function_call = Expr(option_level[1].type, [arg.content for arg in option_level[2:end]]...)
                @info "Adding function call to options $function_call"
                push!(options, function_call)
                option_level = []
                prev_pos = 0
            end
            if in_option_call && arg == last(option_args)
                in_option_call = false
                push!(option_level, arg)
                @info "Stepping out of function call at $arg"
                function_call = Expr(option_level[1].type, [arg.content for arg in option_level[2:end]]...)
                @info "Adding function call to options $function_call"
                push!(options, function_call)
                option_level = []
                prev_pos = 0
                continue
            end
            if arg.type == :call
                in_option_call = true
                @info "Stepping into function call at $arg"
                push!(option_level, arg)
                continue
            end
            if in_option_call
                @info "Adding $arg to function call"
                push!(option_level, arg)
                prev_pos = arg.tree_position
                continue
            end
            if !in_option_call
                @info "Adding argument to options $arg"
                push!(options, arg.content)
            end
        end
    end
    @info "Options are $options"
    return options
end

# FIXME this part should be another State Machine
function transpile(ast::Vector{Node})
    command = ast[1].content
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = Vector{Node}()
    opt_values = []
    cond_values = []
    in_command = true
    in_condition = false
    in_options = false
    @info "Starting in command"
    for arg in ast
        if arg.type == :macrocall && arg.content == Symbol("@if")
            in_command = false
            in_condition = true
            @info "Stepping out of command at $arg"
            @info "Stepping into condition at $arg"
        end
        if in_condition && arg.type == :call && !in(arg.content, SYMBOLS)
            in_condition = false
            in_options = true
            @info "Stepping out of condition at $arg"
            @info "Stepping into options at $arg"
        end
        if in_command
            if arg.type in [:call, Symbol, Int64]
                push!(arguments, arg)
            end
        end
        if in_condition
            if arg.type in [:call, Symbol, Int64] && arg.content != Symbol("@if")
                push!(cond_values, arg.content)
                condition = push!(condition, arg)
            end
        end
        if in_options
            if arg.type in [:call ,Symbol, Int64]
                push!(opt_values, arg.content)
                push!(options, arg)
            end
        end
    end
    return (command, arguments, condition, options)
end

macro keep(exprs...)
    command = Symbol("@keep")
    args = parse(exprs)
    (_, arguments, condition, options) = transpile(args)
    arguments = construct_calls(arguments)
    condition = construct_calls(condition)[1]
    options = construct_calls(options)
    cmd = Command(
    command,
    Tuple(arguments),
    Where(condition),
    Options(Tuple(options))
    )
    return cmd
end

if abspath(PROGRAM_FILE) == @__FILE__
    cmd = @keep a b @if d == 1, cluster(z) whatever drop(x) peek pipe(y,x)
    println(cmd)
end