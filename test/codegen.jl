module MyModule
myfunc(x) = 2x
myaggreg(v::Vector) = sum(x.^2)
mymiss(::Missing) = missing
mymiss(x) = 3x
end

@testset "Replace variable references" begin
    @test_expr replace_variable_references(:(x + y + f(z) - g.(x))) == :(:x + :y + f(:z) - g.(:x))
    @test_expr replace_variable_references(:(f(x, <=))) == :(f(:x, <=))
end

@testset "Bitmask" begin
    df = DataFrame(x = [1, 2, missing, 4])
    @test_expr Kezdi.build_bitmask(:df, :(x < 4)) == :(falses(nrow(df)) .| Missings.replace(df.x .< 4, false))
    @test eval(Kezdi.build_bitmask(:(DataFrame(x = [1, 2, missing, 4])), :(2 < 4))) == [true, true, true, true]
end

@testset "Vectorize function calls" begin
    @test_expr vectorize_function_calls(:(log(x))) == :(log.(x))
    @test_expr vectorize_function_calls(:(x + y)) == :(x .+ y) 
    @test_expr vectorize_function_calls(:(log(x) + log(z))) == :(log.(x) .+ log.(z))
    @test_expr vectorize_function_calls(:(div(x, y))) == :(div.(x, y))
    @test_expr vectorize_function_calls(:(1 + div(x, y, z))) == :(1 .+ div.(x, y, z))
    @testset "Do not vectorize" begin
        @test_expr vectorize_function_calls(:(mean(x))) == :(mean(keep_only_values(x)))
        @test_expr vectorize_function_calls(:(mean(x) + log(y))) == :(mean(keep_only_values(x)) .+ log.(y))
        @test_expr vectorize_function_calls(:(log.(x))) == :(log.(x))
        @test_expr vectorize_function_calls(:(log(x) + sum(y))) == :(log.(x) .+ sum(keep_only_values(y)))
        @test_expr vectorize_function_calls(:(wsum(x))) == :(wsum(keep_only_values(x)))
        @test_expr vectorize_function_calls(:(std(x))) == :(std(keep_only_values(x)))
    end

    @testset "Explicit DNV request" begin
        @test_expr vectorize_function_calls(:(DNV(x))) == :(x)
        @test_expr vectorize_function_calls(:(DNV(x + y))) == :(x + y)
        @test_expr vectorize_function_calls(:(DNV(log(x)))) == :(log(x))
        @test_expr vectorize_function_calls(:(DNV(log(x) + 1))) == :(log(x) + 1)
    end

    @testset "Unknown functions are vectorized" begin
        df2 = @with DataFrame(x = 1:10) @generate y = Dates.year(x)
        @test df2.y == Dates.year.(df2.x)
    end

    @testset "Unknown functions are passed through `passmissing`" begin
        @test_expr vectorize_function_calls(:(y = Dates.year(x))) == :(y = (passmissing(Dates.year)).(x))
    end
    @testset "Functions in other modules" begin
        using .MyModule
        @test vectorize_function_calls(:(MyModule.myfunc(x))) == :((passmissing(MyModule.myfunc)).(x))       
        @test vectorize_function_calls(:(MyModule.myaggreg(x))) == :(MyModule.myaggreg(keep_only_values(x)))  
        @test vectorize_function_calls(:(MyModule.mymiss(x))) == :(MyModule.mymiss.(x))     
    end

    @testset "Functions in other modules with DNV" begin
        using .MyModule
        @test vectorize_function_calls(:(DNV(MyModule.myfunc(x)))) == :(MyModule.myfunc(x))
        @test vectorize_function_calls(:(DNV(MyModule.myaggreg(x)))) == :(MyModule.myaggreg(x))
        @test vectorize_function_calls(:(DNV(MyModule.mymiss(x)))) == :(MyModule.mymiss(x))
    end
end
