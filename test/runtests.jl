using Test
using Expronicon
using Kezdi
using Logging
global_logger(ConsoleLogger(stderr, Logging.Info))

TEST_CASES = [
    (ex="@mockmacro df a b", command=:keep, arguments=[:a, :b], condition=nothing, options=[]),
    (ex="@mockmacro df d = 1", command=:generate, arguments=[:(d = 1)], condition=nothing, options=[]),
    (ex="@mockmacro df d", command=:summarize, arguments=[:d], condition=nothing, options=[]),
    (ex="@mockmacro df y x, robust", command=:regress, arguments=[:y, :x], condition=nothing, options=[:robust]),
    (ex="@mockmacro df y x, absorb(country)", command=:regress, arguments=[:y, :x], condition=nothing, options=[:(absorb(country))]),
    (ex="@mockmacro df y log(x), robust", command=:regress, arguments=[:y, :(log(x))], condition=nothing, options=[:robust]),
    (ex="@mockmacro df x, detail", command=:summarize, arguments=[:x], condition=nothing, options=[:detail]),
    (ex="@mockmacro df x @if x < 0", command=:summarize, arguments=[:x], condition=:(x < 0), options=[]),
    (ex="@mockmacro df x @if ln(x) < 0", command=:summarize, arguments=[:x], condition=:(ln(x) < 0), options=[]),
    (ex="@mockmacro df x @if x < 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0), options=[:detail]),
    (ex="@mockmacro df x @if x < 0 && y > 0", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[]),   
    (ex="@mockmacro df x @if x < 0 && y > 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[:detail]),   
]

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
replace_variable_references = Kezdi.replace_variable_references
vectorize_function_calls = Kezdi.vectorize_function_calls
transpile = Kezdi.transpile
rewrite = Kezdi.rewrite

@testset "Parsing" begin
    include("parse.jl")
end

@testset "Commands" begin
    include("commands.jl")
end

@testset "Code generation" begin
    include("codegen.jl")
end