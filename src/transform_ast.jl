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

function transform_if(ast)
    if isa(ast, Expr)
        if ast.head == :macrocall && ast.args[1] == Symbol("@if")
            return  Expr(:macrocall, Symbol("@where"), map(transform_if, ast.args[2:end])...)
        else
            return Expr(ast.head, map(transform_if, ast.args)...)
        end
    else
        return ast
    end
end

function extract_args(arg)
    if isa(arg, Expr)
        return (arg.head, arg)
    else
        return (typeof(arg), arg)
    end
end

function parse_ast(ast)
    args = Vector{Tuple{Union{Type,Symbol},Any}}()
    if ast.args != []
        for arg in ast.args
            if arg == ast.args[1]
                push!(args, (ast.head, arg))
            end
            if isa(arg, Expr)
                push!(args, parse_ast(arg)...)
            else
                push!(args, extract_args(arg))
            end
        end
    end
    return args
end


if abspath(PROGRAM_FILE) == @__FILE__
    ex = :(@keep a b @if d == 1, cluster(z) whatever)
    args = parse_ast(ex)
    for arg in args
        println(arg)
    end
end