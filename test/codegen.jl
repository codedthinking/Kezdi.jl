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

@testset "Assignment formula" begin
    @testset "RHS variables" begin
        @test_expr build_assignment_formula(:(y = x)) == :([:x] => (((x,) -> x) => :y))
        @test_expr build_assignment_formula(:(y = x + z)) == :([:x, :z] => (((x, z) -> x + z) => :y))
        @test_expr build_assignment_formula(:(y = x + 1)) == :([:x] => (((x,) -> x + 1) => :y))
    end
    @testset "RHS functions" begin
        @test_expr build_assignment_formula(:(y = f(x))) == :([:x] => ((x,) -> f(x)) => :y)
        @test_expr build_assignment_formula(:(y = f(x, z))) == :([:x, :z] => ((x, z) -> f(x, z)) => :y)
        @test_expr build_assignment_formula(:(y = f(x, z) + 1)) == :([:x, :z] => ((x, z) -> f(x, z) + 1) => :y)
        @test_expr build_assignment_formula(:(y = f.(x))) == :([:x] => ((x,) -> f.(x)) => :y)
    end
    @testset "RHS constants" begin
        @test_expr build_assignment_formula(:(y = 1)) == :(((_,) -> 1) => :y)
        @test_expr build_assignment_formula(:(y = 1 + 1)) == :(((_,) -> 1 + 1) => :y)
        @test_expr build_assignment_formula(:(y = f(1))) == :(((_,) -> f(1)) => :y)
    end
    @testset "Boolean operators" begin
        @test_expr build_assignment_formula(:(y = x == 0)) == :([:x] => ((x,) -> x == 0) => :y)
        @test_expr build_assignment_formula(:(y = x < 0)) == :([:x] => ((x,) -> x < 0) => :y)
        @test_expr build_assignment_formula(:(y = x < 0 && z > 0)) == :([:x, :z] => ((x, z) -> x < 0 && z > 0) => :y)
    end
    @testset "Reserved words" begin
        @test_expr build_assignment_formula(:(y = f(String))) == :(((_,) -> f(String)) => :y)
    end
    @testset "Type checking" begin
        @test_expr build_assignment_formula(:(y = x isa String)) == :([:x] => ((x,) -> x isa String) => :y)
    end
end
