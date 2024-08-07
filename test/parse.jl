TEST_CASES = [
    (ex="@mockmacro a b", command=:keep, arguments=[:a, :b], condition=nothing, options=[]),
    (ex="@mockmacro d = 1", command=:generate, arguments=[:(d = 1)], condition=nothing, options=[]),
    (ex="@mockmacro d", command=:summarize, arguments=[:d], condition=nothing, options=[]),
    (ex="@mockmacro y x, robust", command=:regress, arguments=[:y, :x], condition=nothing, options=[:robust]),
    (ex="@mockmacro y x, robust", command=:regress, arguments=[:y, :x], condition=nothing, options=[:robust]),
    (ex="@mockmacro y = x, absorb(country)", command=:regress, arguments=[:(y = x)], condition=nothing, options=[:(absorb(country))]),
    (ex="@mockmacro y = x, absorb(country) robust", command=:regress, arguments=[:(y = x)], condition=nothing, options=[:(absorb(country)), :robust]),
    (ex="@mockmacro y log(x), robust", command=:regress, arguments=[:y, :(log(x))], condition=nothing, options=[:robust]),
    (ex="@mockmacro y = log(x), robust", command=:regress, arguments=[:(y = log(x))], condition=nothing, options=[:robust]),
    (ex="@mockmacro x, detail", command=:summarize, arguments=[:x], condition=nothing, options=[:detail]),
    (ex="@mockmacro x @if x < 0", command=:summarize, arguments=[:x], condition=:(x < 0), options=[]),
    (ex="@mockmacro x @if ln(x) < 0", command=:summarize, arguments=[:x], condition=:(ln(x) < 0), options=[]),
    (ex="@mockmacro x @if x < 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0), options=[:detail]),
    (ex="@mockmacro x @if x < 0 && y > 0", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[]),   
    (ex="@mockmacro x @if x < 0 && y > 0, detail", command=:summarize, arguments=[:x], condition=:(x < 0 && y > 0), options=[:detail]),   
]


@testset "Arguments are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        expressions = preprocess(case.ex)
        command = parse(expressions, case.command)
        @test command.arguments == tuple(case.arguments...)
    end
end

@testset "Condition is parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if !isnothing(case.condition)
            expressions = preprocess(case.ex)
            command = parse(expressions, case.command)
            @test command.condition == case.condition
        end
    end
end

@testset "Options are parsed" begin
    @testset "$(case.ex)" for case in TEST_CASES
        if length(case.options) > 0
            expressions = preprocess(case.ex)
            command = parse(expressions, case.command)
            @test command.options == tuple(case.options...)
        end
    end
end
