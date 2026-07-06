using Test
using Kezdi
using Logging

macro return_arguments(expr)
    return (expr,)
end

macro return_arguments(exprs...)
    return exprs
end

# Drop-in replacement for Expronicon.@test_expr: compare two `Expr`s for
# structural equality while ignoring line-number nodes.
normalize_expr(x) = x
normalize_expr(ex::Expr) = Base.remove_linenums!(deepcopy(ex))

macro test_expr(ex)
    Meta.isexpr(ex, :call, 3) && ex.args[1] == :(==) ||
        error("@test_expr expects `lhs == rhs`")
    :(@test normalize_expr($(esc(ex.args[2]))) == normalize_expr($(esc(ex.args[3]))))
end

function preprocess(command::AbstractString)::Tuple
    new_command = replace(command, r"@(\w+)" => "@return_arguments", count=1)
    return eval(Meta.parse(new_command))
end

build_assignment_formula = Kezdi.build_assignment_formula
replace_column_references = Kezdi.replace_column_references
vectorize_function_calls = Kezdi.vectorize_function_calls
parse = Kezdi.parse
rewrite = Kezdi.rewrite

@testset "Kezdi.jl" begin
@testset "Aqua" begin
    include("aqua.jl")
end

@testset "Parsing" begin
    include("parse.jl")
end

@testset "Commands" begin
    include("commands.jl")
end

@testset "Code generation" begin
    include("codegen.jl")
end

@testset "With.jl" begin
    include("With.jl")
end

@testset "Functions" begin
    include("functions.jl")
end
end # all tests