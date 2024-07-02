@testset "Replace variable references" begin
    @test_expr replace_variable_references(:(x + y + f(z) - g.(x))) == :(:x + :y + f(:z) - g.(:x))
    @test_expr replace_variable_references(:(f(x, <=))) == :(f(:x, <=))
end

@testset "Vectorize function calls" begin
    @test_expr vectorize_function_calls(:(log(x))) == :(log.(x))
    @test_expr vectorize_function_calls(:(x + y)) == :(x .+ y) 
    @test_expr vectorize_function_calls(:(log(x) + log(z))) == :(log.(x) .+ log.(z))
    @test_expr vectorize_function_calls(:(div(x, y))) == :(div.(x, y))
    @test_expr vectorize_function_calls(:(1 + div(x, y, z))) == :(1 .+ div.(x, y, z))
    @testset "Do not vectorize" begin
        @test_expr vectorize_function_calls(:(mean(x))) == :(mean(skipmissing(x)))
        @test_expr vectorize_function_calls(:(mean(x) + log(y))) == :(mean(skipmissing(x)) .+ log.(y))
        @test_expr vectorize_function_calls(:(log.(x))) == :(log.(x))
        @test_expr vectorize_function_calls(:(log(x) + sum(y))) == :(log.(x) .+ sum(skipmissing(y)))
        @test_expr vectorize_function_calls(:(wsum(x))) == :(wsum(skipmissing(x)))
        @test_expr vectorize_function_calls(:(std(x))) == :(std(skipmissing(x)))
    end

    @testset "Explicit DNV request" begin
        @test_expr vectorize_function_calls(:(DNV(x))) == :(x)
        @test_expr vectorize_function_calls(:(DNV(x + y))) == :(x + y)
        @test_expr vectorize_function_calls(:(DNV(log(x)))) == :(log(x))
        @test_expr vectorize_function_calls(:(DNV(log(x) + 1))) == :(log(x) + 1)
    end
end
