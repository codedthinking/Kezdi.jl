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
@testset "Every command begins with a macrocall" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expression = Meta.parse(case.ex)
        nodes = parse_ast(expression)
        @test nodes[1].type == :macrocall
    end
end

@testset "Command name is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expression = Meta.parse(case.ex)
        nodes = parse_ast(expression)
        expected_name = Symbol("@$(case.command)")
        @test nodes[1].content == expected_name
    end
end

@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expression = Meta.parse(case.ex)
        (command, arguments, condition, options) = transpiler(parse_ast(expression))
        @test_skip [arg.content for arg in arguments] == case.arguments
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in [for x in TEST_CASES if length(x.condition) > 0]
        expression = Meta.parse(case.ex)
        (command, arguments, condition, options) = transpiler(parse_ast(expression))
        @test [arg.content for arg in condition] == case.condition
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in [for x in TEST_CASES if length(x.options) > 0]
        expression = Meta.parse(case.ex)
        (command, arguments, condition, options) = transpiler(parse_ast(expression))
        @test [arg.content for arg in options] == case.options
    end
end
