using Test
using Expronicon
using Kezdi
using Logging

macro return_arguments(expr)
    return (expr,)
end

macro return_arguments(exprs...)
    return exprs
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
end # all tests