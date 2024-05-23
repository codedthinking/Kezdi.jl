using Test
include("../src/transpiler.jl")

TEST_CASES = [
    (ex="@keep a b", command=:keep, arguments=[:a, :b], condition=[], options=[]),
    (ex="@generate d = 1", command=:generate, arguments=[:d], condition=[], options=[]),
    (ex="@summarize d", command=:summarize, arguments=[:d], condition=[], options=[]),
    (ex="@regress y x, robust", command=:regress, arguments=[:y, :x], condition=[], options=[:robust]),
    (ex="@summarize x, detail", command=:summarize, arguments=[:x], condition=[], options=[:detail]),
    (ex="@summarize x @if x < 0, detail", command=:summarize, arguments=[:x], condition=[:<, :x, 0], options=[:detail]),
]

macro return_arguments(expr)
    return (expr,)
end

macro return_arguments(exprs...)
    return exprs
end

function preprocess(command::AbstractString)::Tuple
    new_command = replace(command, r"@(\w+)" => "@return_arguments")
    return eval(Meta.parse(new_command))
end

@testset "Every command begins with a macrocall" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        nodes = parse(expressions)
        @test nodes[1].type == :macrocall
    end
end

@testset "Command name is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        nodes = parse(expressions)
        expected_name = Symbol("@$(case.command)")
        @test nodes[1].content == expected_name
    end
end

@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions)
        @info command
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.condition) > 0
            expressions = preprocess(case.ex)
            command = transpile(expressions)
            @info command
        end
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.options) > 0
            expressions = preprocess(case.ex)
            command = transpile(expressions)
            @info command
        end
    end
end
