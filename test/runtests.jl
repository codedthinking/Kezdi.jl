using Test
include("../src/transpiler.jl")

TEST_CASES = [
    (ex="@keep df a b", command=:keep, arguments=[:a, :b], condition=nothing, options=[]),
    (ex="@generate df d = 1", command=:generate, arguments=[:(d = 1)], condition=nothing, options=[]),
    (ex="@summarize df d", command=:summarize, arguments=[:d], condition=nothing, options=[]),
    (ex="@regress df y x, robust", command=:regress, arguments=[:y, :x], condition=nothing, options=[:robust]),
    (ex="@regress df y x, absorb(country)", command=:regress, arguments=[:y, :x], condition=nothing, options=[:(absorb(country))]),
    (ex="@regress df y log(x), robust", command=:regress, arguments=[:y, :(log(x))], condition=nothing, options=[:robust]),
    (ex="@summarize df x, detail", command=:summarize, arguments=[:x], condition=nothing, options=[:detail]),
    (ex="@summarize df x @if x < 0", command=:summarize, arguments=[:x], condition=:(x < 0), options=[]),
    (ex="@summarize df x @if ln(x) < 0", command=:summarize, arguments=[:x], condition=:(ln(x) < 0), options=[]),
    (ex="@summarize df x @if x < 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0), options=[:detail]),
    (ex="@summarize df x @if x < 0 && y > 0", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[]),   
    (ex="@summarize df x @if x < 0 && y > 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[:detail]),   
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

@testset "All tests" begin
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