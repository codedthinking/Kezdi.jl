@testset "Replace variable references" begin
    @test_expr replace_variable_references(:(x + y + f(z) - g.(x))) == :(:x + :y + f(:z) - g.(:x))
    @test_expr replace_variable_references(:(f(x, <=))) == :(f(:x, <=))
end

@testset "Vectorize function calls" begin
    @test_expr vectorize_function_calls(:(f(x))) == :(f.(x))
    @test_expr vectorize_function_calls(:(x + y)) == :(x .+ y) 
    @test_expr vectorize_function_calls(:(f(x) + g(z))) == :(f.(x) .+ g.(z))
    @test_expr vectorize_function_calls(:(f(x, y))) == :(f.(x, y))
    @test_expr vectorize_function_calls(:(1 + f(x, y, z))) == :(1 .+ f.(x, y, z))
    @testset "Do not vectorize" begin
        @test_expr vectorize_function_calls(:(mean(x))) == :(mean(x))
        @test_expr vectorize_function_calls(:(mean(x) + f(y))) == :(mean(x) .+ f.(y))
        @test_expr vectorize_function_calls(:(f.(x))) == :(f.(x))
    end
end
