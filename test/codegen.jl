module MyModule
myfunc(x) = 2x
myaggreg(v::Vector) = sum(x.^2)
mymiss(::Missing) = missing
mymiss(x) = 3x
end

@testset "Command priting" begin
    @test string(Kezdi.Command(:generate, (:(x = 2),), nothing, ())) == "@generate x = 2"
    @test string(Kezdi.Command(:generate, (:(x = 2),), :(y < 2), ())) == "@generate x = 2 @if y < 2"
    @test string(Kezdi.Command(:regress, (:y, :x), :(y < 2), (:robust, ))) == "@regress y x @if y < 2, robust"    
    @test Kezdi.Command(:collapse, (:(mean_x = mean(x)), :(sum_x = sum(x))), :(x > 2), (:(by(y)),)) |> string == "@collapse mean_x = mean(x) sum_x = sum(x) @if x > 2, by(y)"
end

@testset "Replace column references" begin
    @test_expr replace_column_references(:(x + y + f(z) - g.(x))) == :(:x + :y + f(:z) - g.(:x))
    @test_expr replace_column_references(:(f(x, <=))) == :(f(:x, <=))
    @test_expr replace_column_references(:(log(x) - log(Main.x))) == :(log(:x) - log(Main.x))
    @test_expr replace_column_references(:(Main.sub.x)) == :(Main.sub.x)
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
        @test_expr vectorize_function_calls(:(~(x + y))) == :(x + y)
        @test_expr vectorize_function_calls(:(~log(x))) == :(log(x))
        @test_expr vectorize_function_calls(:(~log(x) + 1)) == :(log(x) .+ 1)
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
        @test vectorize_function_calls(:(~(MyModule.myfunc(x)))) == :(MyModule.myfunc(x))
        @test vectorize_function_calls(:(~(MyModule.myaggreg(x)))) == :(MyModule.myaggreg(x))
        @test vectorize_function_calls(:(~(MyModule.mymiss(x)))) == :(MyModule.mymiss(x))
    end
end

@testset "Helper functions" begin
    @testset "operates_on_type" begin
        @test Kezdi.operates_on_type(:log, Number)
        @test !Kezdi.operates_on_type(:log, String)
        @test Kezdi.operates_on_type(:log, Missing)
        @test !Kezdi.operates_on_type(:sum, Missing)
        @test !Kezdi.operates_on_type(:sum, Missing)
        @test !Kezdi.operates_on_type(:log, AbstractVector)

        @test_throws Exception Kezdi.operates_on_type(4, Missing)

        @test Kezdi.operates_on_missing(:log)
        @test !Kezdi.operates_on_missing(:sum)
        @test Kezdi.operates_on_vector(:mean)
        @test !Kezdi.operates_on_vector(:log)
    end

    @testset "split_assignment" begin
        @test Kezdi.isassignment(:(x = 2))
        @test !Kezdi.isassignment(:(x == 2))
        @test Kezdi.split_assignment(:(x = 2)) == (:x, 2)
        @test Kezdi.split_assignment(:(x = 2 + 3)) == (:x, :(2 + 3))
        @test Kezdi.split_assignment(:(x = f(y) + 1)) == (:x, :(f(y) + 1))
    end

    @testset "get_LHS" begin
        @test Kezdi.get_LHS(:(x = 2)) == "x"
        @test Kezdi.get_LHS(:(x = 2 + 3)) == "x"
        @test Kezdi.get_LHS(:(x = f(y) + 1)) == "x"
    end

    @testset "Operators" begin
        @test Kezdi.is_operator(:+)
        @test !Kezdi.is_operator(:x)
        @test !Kezdi.is_operator(:log)
        @test Kezdi.is_operator(:&&)
        @test Kezdi.is_operator(:<=)
        @test Kezdi.is_dotted_operator(:.+)
    end

    @testset "Variable reference and function call" begin
        @test Kezdi.iscolreference(:x)
        @test !Kezdi.iscolreference(:(x.y))
        @test !Kezdi.iscolreference(:(log(x)))
        @test Kezdi.isfunctioncall(:(log(x)))
        @test Kezdi.isfunctioncall(:(log.(x)))
        @test Kezdi.isfunctioncall(:(log.(x, y)))
        @test Kezdi.isfunctioncall(:(Main.log(x)))
        @test !Kezdi.isfunctioncall(:x)
    end

    @testset "get_dot_parts" begin
        @test Kezdi.get_dot_parts(:x) == [:x]
        @test Kezdi.get_dot_parts(:(x.y)) == [:x, :y]
        @test Kezdi.get_dot_parts(:(x.y.z)) == [:x, :y, :z]
    end

    @testset "Add skipmissing" begin
        @test Kezdi.add_skipmissing(:(log(df.x))) == :(log(skipmissing(df.x)))
        @test Kezdi.add_skipmissing(:(log(df.x)-log(df.y))) == :(log(skipmissing(df.x)) - log(skipmissing(df.y)))
        @test Kezdi.add_skipmissing(:(log(df.x - df.y))) == :(log(skipmissing(df.x) - skipmissing(df.y)))
    end
end
