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
    # plain function calls are wrapped in Kezdi.apply_function, which decides at
    # run time whether to broadcast or pass the whole column; operators are still
    # dotted at expansion time
    @test_expr vectorize_function_calls(:(log(x))) == :(Kezdi.apply_function(log, x))
    @test_expr vectorize_function_calls(:(x + y)) == :(x .+ y)
    @test_expr vectorize_function_calls(:(log(x) + log(z))) == :(Kezdi.apply_function(log, x) .+ Kezdi.apply_function(log, z))
    @test_expr vectorize_function_calls(:(div(x, y))) == :(Kezdi.apply_function(div, x, y))
    @test_expr vectorize_function_calls(:(1 + div(x, y, z))) == :(1 .+ Kezdi.apply_function(div, x, y, z))
    @testset "Aggregating functions also go through apply_function" begin
        @test_expr vectorize_function_calls(:(mean(x))) == :(Kezdi.apply_function(mean, x))
        @test_expr vectorize_function_calls(:(mean(x) + log(y))) == :(Kezdi.apply_function(mean, x) .+ Kezdi.apply_function(log, y))
        @test_expr vectorize_function_calls(:(log.(x))) == :(log.(x))
        @test_expr vectorize_function_calls(:(log(x) + sum(y))) == :(Kezdi.apply_function(log, x) .+ Kezdi.apply_function(sum, y))
        @test_expr vectorize_function_calls(:(wsum(x))) == :(Kezdi.apply_function(wsum, x))
        @test_expr vectorize_function_calls(:(std(x))) == :(Kezdi.apply_function(std, x))
    end

    @testset "multi-argument ismissing routes to anymissing" begin
        # multi-arg ismissing is rewritten to anymissing, then (like every plain
        # call) dispatched through apply_function; anymissing/ismissing broadcast
        # element-wise at run time (operates_on_missing is true for both)
        @test_expr vectorize_function_calls(:(ismissing(x, y))) == :(Kezdi.apply_function(anymissing, x, y))
        @test_expr vectorize_function_calls(:(ismissing(x))) == :(Kezdi.apply_function(ismissing, x))
        @test Kezdi.anymissing(missing, 2) == true
        @test Kezdi.anymissing(1, 2) == false
        @test Kezdi.anymissing(1, missing, 3) == true
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

    @testset "Unknown functions go through apply_function" begin
        @test_expr vectorize_function_calls(:(y = Dates.year(x))) == :(y = Kezdi.apply_function(Dates.year, x))
    end
    @testset "Functions in other modules" begin
        using .MyModule
        @test vectorize_function_calls(:(MyModule.myfunc(x))) == :(Kezdi.apply_function(MyModule.myfunc, x))
        @test vectorize_function_calls(:(MyModule.myaggreg(x))) == :(Kezdi.apply_function(MyModule.myaggreg, x))
        @test vectorize_function_calls(:(MyModule.mymiss(x))) == :(Kezdi.apply_function(MyModule.mymiss, x))
    end

    @testset "Functions in other modules with DNV" begin
        using .MyModule
        @test vectorize_function_calls(:(~(MyModule.myfunc(x)))) == :(MyModule.myfunc(x))
        @test vectorize_function_calls(:(~(MyModule.myaggreg(x)))) == :(MyModule.myaggreg(x))
        @test vectorize_function_calls(:(~(MyModule.mymiss(x)))) == :(MyModule.mymiss(x))
    end
end

@testset "Helper functions" begin
    @testset "runtime vectorization decisions" begin
        using .MyModule
        # decisions are now made on the function VALUE at run time, not on the
        # symbol at expansion time
        @test Kezdi.operates_on_vector(mean)
        @test Kezdi.operates_on_vector(sum)
        @test Kezdi.operates_on_vector(wsum)
        @test !Kezdi.operates_on_vector(log)
        @test Kezdi.operates_on_missing(log)
        @test !Kezdi.operates_on_missing(sum)
        @test Kezdi.operates_on_vector(MyModule.myaggreg)
        @test Kezdi.operates_on_missing(MyModule.mymiss)
        @test !Kezdi.operates_on_vector(MyModule.myfunc)

        # apply_function end to end (isequal because comparisons involve missing)
        @test isequal(Kezdi.apply_function(log, [1.0, missing]), [log(1.0), missing])
        @test Kezdi.apply_function(mean, [1.0, missing, 3.0]) == 2.0
        @test isequal(Kezdi.apply_function(Dates.year, [Date(2020, 1, 1), missing]), [2020, missing])
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
