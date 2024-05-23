using Test
include("../src/transpiler.jl")

TEST_CASES = [
    (ex="@keep a b", command=:keep, arguments=[:a, :b], condition=[], options=[]),
    (ex="@generate d = 1", command=:generate, arguments=[:d], condition=[], options=[]),
    (ex="@summarize d", command=:summarize, arguments=[:d], condition=[], options=[]),
    (ex="@regress y x, robust", command=:regress, arguments=[:y, :x], condition=[], options=[:robust]),
    (ex="@regress y x, absorb(country)", command=:regress, arguments=[:y, :x], condition=[], options=[:absorb, :country]),
    (ex="@regress y log(x), robust", command=:regress, arguments=[:y, :log, :x], condition=[], options=[:robust]),
    (ex="@summarize x, detail", command=:summarize, arguments=[:x], condition=[], options=[:detail]),
    (ex="@summarize x @if x < 0", command=:summarize, arguments=[:x], condition=[:<, :x, 0], options=[]),
    (ex="@summarize x @if ln(x) < 0", command=:summarize, arguments=[:x], condition=[:<, :ln, :x, 0], options=[]),
    (ex="@summarize x @if x < 0, detail", command=:summarize, arguments=[:x], condition=[:<, :x, 0], options=[:detail]),
    (ex="@summarize x @if x < 0 && y > 0, detail", command=:summarize, arguments=[:x], condition=[:&&, [:<, :x, 0], [:>, :y, 0]], options=[:detail]),   
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

@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions, case.command)
        @test command.arguments == tuple(case.arguments...)
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.condition) > 0
            expressions = preprocess(case.ex)
            command = transpile(expressions, case.command)
            @info command
        end
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.options) > 0
            expressions = preprocess(case.ex)
            command = transpile(expressions, case.command)
            @info command
        end
    end
end
