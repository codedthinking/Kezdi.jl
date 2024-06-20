using Test
using Expronicon
include("../src/consts.jl")
include("../src/transpiler.jl")
include("../src/codegen.jl")

TEST_CASES = [
    (ex="@keep a b", command=:keep, arguments=[:a, :b], condition=nothing, options=[]),
    (ex="@generate d = 1", command=:generate, arguments=[:(d = 1)], condition=nothing, options=[]),
    (ex="@summarize d", command=:summarize, arguments=[:d], condition=nothing, options=[]),
    (ex="@regress y x, robust", command=:regress, arguments=[:y, :x], condition=nothing, options=[:robust]),
    (ex="@regress y x, absorb(country)", command=:regress, arguments=[:y, :x], condition=nothing, options=[:(absorb(country))]),
    (ex="@regress y log(x), robust", command=:regress, arguments=[:y, :(log(x))], condition=nothing, options=[:robust]),
    (ex="@summarize x, detail", command=:summarize, arguments=[:x], condition=nothing, options=[:detail]),
    (ex="@summarize x @if x < 0", command=:summarize, arguments=[:x], condition=:(x < 0), options=[]),
    (ex="@summarize x @if ln(x) < 0", command=:summarize, arguments=[:x], condition=:(ln(x) < 0), options=[]),
    (ex="@summarize x @if x < 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0), options=[:detail]),
    (ex="@summarize x @if x < 0 && y > 0", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[]),   
    (ex="@summarize x @if x < 0 && y > 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[:detail]),   
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


@testset "Assignment formula" begin
    @testset "RHS varibles" begin
        @test_expr build_assignment_formula(:(y = x)) == :([:x] => (x,) -> x => :y)
        @test_expr build_assignment_formula(:(y = x + z)) == :([:x, :z] => (x, z) -> x + z => :y)
        @test_expr build_assignment_formula(:(y = x + 1)) == :([:x] => (x,) -> x + 1 => :y)
    end
    @testset "RHS functions" begin
        @test_expr build_assignment_formula(:(y = f(x))) == :([:x] => (x,) -> f(x) => :y)
        @test_expr build_assignment_formula(:(y = f(x, z))) == :([:x, :z] => (x, z) -> f(x, z) => :y)
        @test_expr build_assignment_formula(:(y = f(x, z) + 1)) == :([:x, :z] => (x, z) -> f(x, z) + 1 => :y)
        @test_expr build_assignment_formula(:(y = f.(x))) == :([:x] => (x,) -> f.(x) => :y)
    end
    @testset "RHS constants" begin
        @test_expr build_assignment_formula(:(y = 1)) == :((_,) -> 1 => :y)
        @test_expr build_assignment_formula(:(y = 1 + 1)) == :((_,) -> 1 + 1 => :y)
        @test_expr build_assignment_formula(:(y = f(1))) == :((_,) -> f(1) => :y)
    end
    @testset "Boolean operators" begin
        @test_expr build_assignment_formula(:(y = x == 0)) == :([:x] => (x,) -> x == 0 => :y)
        @test_expr build_assignment_formula(:(y = x < 0)) == :([:x] => (x,) -> x < 0 => :y)
        @test_expr build_assignment_formula(:(y = x < 0 && z > 0)) == :([:x, :z] => (x, z) -> x < 0 && z > 0 => :y)
    end
    @testset "Reserved words" begin
        @test_expr build_assignment_formula(:(y = f(String))) == :((_,) -> f(String) => :y)
    end
    @testset "Type checking" begin
        @test_expr build_assignment_formula(:(y = x isa String)) == :([:x] => (x,) -> x isa String => :y)
    end
end

@testset "Replace variable references" begin
    @test_expr replace_variable_references(:(x + y + f(z) - g.(x))) == :(:x + :y + f(:z) - g.(:x))
    @test_expr replace_variable_references(:(f(x, <=))) == :(f(:x, <=))
end

@testset "Parsing tests" begin
@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions, case.command)
        @test command.arguments == tuple(case.arguments...)
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if !isnothing(case.condition)
            expressions = preprocess(case.ex)
            command = transpile(expressions, case.command)
            @warn typeof(command.condition), typeof(case.condition)
            @test command.condition == case.condition
        end
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.options) > 0
            expressions = preprocess(case.ex)
            command = transpile(expressions, case.command)
            @test command.options == tuple(case.options...)
        end
    end
end
end 