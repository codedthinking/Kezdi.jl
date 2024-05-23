using Test
include("../src/transpiler.jl")
include("../src/codegen.jl")

TEST_CASES = [
    (ex="@keep a b",
        command=:keep, 
        arguments=(:a, :b), 
        condition=nothing, 
        options=[]),
    (ex="@generate d = 1",                     
        command=:generate, 
        arguments=[:d], 
        condition=nothing, 
        options=[]),
    (ex="@summarize d",                             
        command=:summarize, 
        arguments=[:d], 
        condition=nothing, 
        options=[]),
    (ex="@regress y x, robust",                     
        command=:regress, 
        arguments=[:y, :x], 
        condition=nothing, 
        options=[:robust]),
    (ex="@regress y x, absorb(country)",            
        command=:regress, 
        arguments=[:y, :x], 
        condition=nothing, 
        options=[:(absorb(country))]),
    (ex="@regress y log(x), robust",                
        command=:regress, 
        arguments=[:y, :log, :x], 
        condition=nothing, 
        options=[:robust]),
    (ex="@summarize x, detail",                     
        command=:summarize, 
        arguments=[:x], 
        condition=nothing, 
        options=[:detail]),
    (ex="@summarize x @if x < 0",                   
        command=:summarize, 
        arguments=[:x], 
        condition=:(x < 0), 
        options=[]),
    (ex="@summarize x @if ln(x) < 0",               
        command=:summarize, 
        arguments=[:x], 
        condition=:(ln(x) < 0), 
        options=[]),
    (ex="@summarize x @if x < 0, detail",           
        command=:summarize, 
        arguments=[:x], 
        condition=:(x < 0), 
        options=[:detail]),
    (ex="@summarize x @if x < 0 && y > 0",          
        command=:summarize, 
        arguments=[:x], 
        condition=:(x < 0 && y > 0), 
        options=[:detail]),   
    (ex="@summarize x @if x < 0 && y > 0, detail",  
        command=:summarize, 
        arguments=[:x], 
        condition=:(x < 0 && y > 0), 
        options=[:detail]),   
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
@testset "Parser" begin
@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions, case.command)
        @test command.arguments == tuple(case.arguments...)
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions, case.command)
        @test command.condition == case.condition
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = transpile(expressions, case.command)
        @test command.options == tuple(case.options...)
    end
end
end # testset

@testset "Generator" begin
    @testset "Dispatch" begin
        @test generate(Command(:keep, (), nothing, ())) == [:(select())]
        @test generate(Command(:replace, (), nothing, ())) == [:(transform())]
    end
end
end # testset

