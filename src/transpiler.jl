using Logging
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

struct Node
    node_type::Union{Symbol, Type}
    content::Union{Expr, Symbol, Number, LineNumberNode}
    level::Int64
    tree_position::Int64
end

struct Where
    condition::Expr
end

struct Options
    options::Tuple{Union{Symbol, Expr}}
end

struct Command 
    command::Symbol
    arguments::Tuple{Symbol}
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

function parse_ast(ast::Expr; depth::Int64=0)::Vector{Node}
    args = Vector{Node}()
    if ast.args != []
        for (i,arg) in enumerate(ast.args)
            if arg == ast.args[1]
                push!(args, Node(ast.head, arg, depth, i))
            end
            if isa(arg, Expr)
                push!(args, parse_ast(arg; depth=depth+1)...)
            else
                push!(args, extract_args(arg; depth=depth, position=i))
            end
        end
    end
    return args
end


function construct_options(nodes::Vector{Node}) 
    syntax_levels = unique([node.syntax_levels for node in nodes])
    for level in syntax_levels
        # use a quasi state machine here too to construct the options.
    end
end

# FIXME this part should be another State Machine
function transpiler(ast::Vector{Node})
    command = ast[1].content
    arguments = Vector{Node}()
    options = Vector{Node}()
    condition = Vector{Node}()
    opt_values = [] # these values are used to avoid duplicates, but should be reset after an option sequence
    cond_values = []
    in_command = false
    in_condition = false
    in_options = false
    for arg in ast
        if arg.node_type == LineNumberNode && !in_condition
            in_command = true
            @info "Stepping into command at $arg"
        end
        if arg.node_type == :macrocall && arg.content == Symbol("@if")
            in_command = false
            in_condition = true
            @info "Stepping out of command at $arg"
            @info "Stepping into condition at $arg"
        end
        if in_condition && arg.node_type == :call && !in(arg.content, SYMBOLS)
            in_condition = false
            in_options = true
            @info "Stepping out of condition at $arg"
            @info "Stepping into options at $arg"
        end
        if in_command
            if arg.node_type in [:call, Symbol, Int64]
                push!(arguments, arg)
            end
        end
        if in_condition
            if arg.node_type in [:call, Symbol, Int64] && arg.content != Symbol("@if")
                if arg.content in cond_values
                    continue
                end
                push!(cond_values, arg.content)
                condition = push!(condition, arg)
            end
        end
        if in_options
            if arg.node_type in [:call ,Symbol, Int64]
                if arg.content in opt_values
                    continue
                end
                push!(opt_values, arg.content)
                push!(options, arg)
            end
        end
    end
    return (command, arguments, condition , options)
end

if abspath(PROGRAM_FILE) == @__FILE__
    ex = :(@keep a b @if d == 1, cluster(z) whatever drop(x) peek pipe(y,x))
    args = parse_ast(ex)
    map(x -> println(x), args)
    (command, arguments, condition, options) = transpiler(args)
    println(command)
    println(arguments)
    println(condition)
    println(options)
    # cmd = Command(
    #     command,
    #     Tuple([arg.content for arg in arguments]),
    #     Where(Expr(condition[1].node_type, [arg.content for arg in condition])),
    #     Options(options)
    # )
end