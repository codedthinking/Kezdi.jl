@testset "Generate" begin
    df = DataFrame(x = 1:4, z = 5:8, s = ["a", "b", "c", "d"])

    @testset "Column added" begin
        df2 = @generate df y = 4.0
        @test "y" in names(df2)
        @test "x" in names(df2) && "z" in names(df2)
        @test df.x == df2.x
        @test df.z == df2.z
    end
    @testset "Known values" begin
        df2 = @generate df y = x
        @test df.x == df2.y
        df2 = @generate df y = x + z
        @test df.x + df.z == df2.y
        df2 = @generate df y = log(z)
        @test log.(df.z) == df2.y
        df2 = @generate df y = 4.0
        @test all(df2.y .== 4.0)
        df2 = @generate df y = sum(x)
        @test all(df2.y .== sum(df.x))
        df2 = @generate df y = sum.(x)
        @test all(df2.y .== df.x)
    end

    @testset "Do not replace special variable names" begin
        df2 = @generate df y = missing
        @test all(ismissing.(df2.y))
        df2 = @generate df y = nothing
        @test all(isnothing.(df2.y))
        df2 = @generate df y = s isa String
        @test all(df2.y)
        df2 = @generate df y = s isa Missing
        @test !any(df2.y)
        df2 = @generate df y = "string" @if s isa String
    end

    @testset "Special varnames" begin
        df2 = @generate df y = _n
        @test all(df2.y .== 1:4)
        df2 = @generate df y = _N
        @test all(df2.y .== 4)
        df2 = @generate df y = -x @if _n < 3
        @test all(df2.y .=== [-1, -2, missing, missing])
        df2 = @generate df y = -x @if _n < _N
        @test all(df2.y .=== [-1, -2, -3, missing])
    end

    @testset "Error handling" begin
        @test_throws Exception @generate df x = 1
    end
end

@testset "Replace" begin
    df = DataFrame(x = 1:4, z = 5:8)

    @testset "Column names don't change" begin
        df2 = @replace df x = 4.0
        @test names(df) == names(df2)
        df2 = @replace df z = 4.0
        @test names(df) == names(df2)
    end
    @testset "Known values" begin
        df2 = @replace df x = log(z)
        @test log.(df.z) == df2.x
        df2 = @replace df x = 4.0
        @test all(df2.x .== 4.0)
        df2 = @replace df z = sum(x)
        @test all(df2.z .== sum(df.x))
        df2 = @replace df z = sum.(x)
        @test all(df2.z .== df.x)
    end

    @testset "Type conversion" begin
        df2 = @replace df x = 4.0
        @test eltype(df2.x) == typeof(4.0)
        df2 = @replace df x = log(z)
        @test eltype(df2.x) == typeof(log(5))
        df2 = @replace df x = 4.0
        df3 = @replace df x = 4
        @test eltype(df.x) == eltype(df3.x)
    end

    @testset "Error handling" begin
        @test_throws Exception @replace df y = 1
    end
end

@testset "Missing values" begin
    df = DataFrame(x = [1, missing, 3])
    @testset "ismissing checks" begin
        df2 = @generate df y = ismissing(x)
        @test df2.y == [false, true, false]
        df2 = @generate df y = 4 @if ismissing(x)
        @test all(df2.y .=== [missing, 4, missing])
        df2 = @replace df x = 2 @if ismissing(x)
        @test df2.x == [1, 2, 3]
    end
end

@testset "Collapse" begin
    @testset "Non-vectorized aggregators" begin
        df = DataFrame(x = 1:4, z = 5:8)
        df2 = @collapse df y = sum(x)
        @test all(df2.y .== sum(df.x))
        df2 = @collapse df y = minimum(x)
        @test all(df2.y .== minimum(df.x))
        df2 = @collapse df y = sum(x) z = minimum(x)
        @test all(df2.y .== sum(df.x))
        @test all(df2.z .== minimum(df.x))
    end
    @testset "Missing values" begin
        df = DataFrame(x = [1, missing, 3])
        df2 = @collapse df y = sum(x)
        @test df2.y == [4]
        df2 = @collapse df y = mean(x)
        @test df2.y == [2.0]
    end
    @testset "Vectorized does not collapse" begin
        df = DataFrame(x = 1:4, z = 5:8)
        df2 = @collapse df y = sum.(x)
        @test all(df2.y .== df.x)
        df2 = @collapse df y = minimum.(x)
        @test all(df2.y .== df.x)
        df2 = @collapse df y = sum.(x) z = minimum(x)
        @test all(df2.y .== df.x)
        @test all(df2.z .== minimum(df.x))         
    end
    @testset "Known values by group(s)" begin
        df = DataFrame(x = 1:6, z = 7:12, s = ["a", "b", "a", "c", "d", "d"], group = ["red", "red", "red", "blue", "blue", "blue"])
        df2 = @collapse df y = sum(x), by(group)
        @test df2.y == [6, 15]
        df2 = @collapse df y = minimum(x), by(group)
        @test df2.y == [1, 4]
        df2 = @collapse df y = sum(x), by(group, s)
        @test df2.y == [4, 2, 4, 11]
        df2 = @collapse df y = minimum(x), by(group, s)
        @test df2.y == [1, 2, 4, 5]
    end
end

@testset "Egen" begin
    df = DataFrame(x = 1:6, s = ["a", "b", "a", "c", "d", "d"], group = ["red", "red", "red", "blue", "blue", "blue"])

    @testset "Column added" begin
        df2 = @egen df y = sum(x)
        @test "y" in names(df2)
        @test "x" in names(df2) && "group" in names(df2)
        @test df.x == df2.x
        @test df.group == df2.group
    end
    @testset "Known values for not vectorized functions" begin
        df2 = @egen df y = sum(x)
        @test all(df2.y .== sum(df.x))
        df2 = @egen df y = minimum(x)
        @test all(df2.y .== minimum(df.x))
        df2 = @egen df y = maximum(x)
        @test all(df2.y .== maximum(df.x))
    end
    @testset "Known values for vectorized functions" begin
        df2 = @egen df y = sum.(x)
        @test all(df2.y .== df.x)
        df2 = @egen df y = minimum.(x)
        @test all(df2.y .== df.x)
        df2 = @egen df y = maximum.(x)
        @test all(df2.y .== df.x)
    end

    @testset "Missing values" begin
        df2 = DataFrame(x = [1, missing, 3])
        @test all((@egen df2 y = sum(x)).y .== 4)
        @test all((@egen df2 y = mean(x)).y .== 2.0)
    end
    @testset "Do not replace special variable names" begin
        df2 = @egen df y = missing
        @test all(ismissing.(df2.y))
        df2 = @egen df y = nothing
        @test all(isnothing.(df2.y))
        df2 = @egen df y = s isa String
        @test all(df2.y)
        df2 = @egen df y = s isa Missing
        @test !any(df2.y)
        df2 = @egen df y = "string" @if s isa String
    end
    @testset "Known values by group(s)" begin
        df2 = @egen df y = sum(x), by(group)
        @test df2.y == [6, 6, 6, 15, 15, 15]
        df2 = @egen df y = minimum(x), by(group)
        @test df2.y == [1, 1, 1, 4, 4, 4]
        df2 = @egen df y = maximum(x), by(group)
        @test df2.y == [3, 3, 3, 6, 6, 6]
        df2 = @egen df y = sum(x), by(group, s)
        @test df2.y == [4, 4, 2, 4, 11, 11]
        df2 = @egen df y = minimum(x), by(group, s)
        @test df2.y == [1, 1, 2, 4, 5, 5]
        df2 = @egen df y = maximum(x), by(group, s)
        @test df2.y == [3, 3, 2, 4, 6, 6]
    end
end

@testset "Keep if" begin
    df = DataFrame(a = 1:4, b = 5:8)
    @test "a" in names(@keep df a)
    @test !("b" in names(@keep df a))
    @test "a" in names(@keep df a @if a < 3)
    @test !("b" in names(@keep df a @if a < 3))
    df2 = @keep df a @if b > 6
    @test all(df2.a .== [3, 4])
end

@testset "Drop if" begin
    df = DataFrame(a = 1:4, b = 5:8)
    @test "a" in names(@drop df b)
    @test !("b" in names(@drop df b))
end


@testset "Generate with if" begin
    df = DataFrame(x = 1:4)
    dfxz = DataFrame(x = 1:4, z = 1:4)
    @testset "Constant conditions" begin
        @testset "True" begin
            df2 = @generate df y = x @if true
            @test df2.y == df.x
            df2 = @generate df y = x @if 2 < 4
            @test df2.y == df.x
            df2 = @generate df y = x @if 2+2 == 4
            @test df2.y == df.x
            df2 = @generate df y = x @if 2+2 == 5 || 2+2 == 4
            @test df2.y == df.x
            df2 = @generate df y = x @if x < 6 || 2+2 == 5
            @test df2.y == df.x
            df2 = @generate df y = x @if 2+2 == 5 || x < 6 
            @test df2.y == df.x
            df2 = @generate df y = x @if 2+2 == 4 && x < 6 
            @test df2.y == df.x
            df2 = @generate df y = x @if x < 6 && 2+2 == 4
            @test df2.y == df.x
            end
        @testset "False" begin
            df2 = @generate df y = x @if false
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 1 == 0
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 1 < 0
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 2+2 == 5 && x <6
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if x < 6 && 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 2+2 == 4 && 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 2+2 == 5 && 2+2 == 4
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 2+2 == 3 || 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if x > 6 || 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if  2+2 == 5 || x > 6
            @test all(df2.y .=== missing)
            end
    end

    @testset "Known conditions" begin
        df2 = @generate df y = x @if x < 3
        @test all(df2.y .=== [1, 2, missing, missing])
    end

    @testset "Condition on other variable" begin
        df2 = @generate dfxz y = x @if z < 3
        @test all(df2.y .=== [1, 2, missing, missing])
    end

    @testset "Window functions operate on subset" begin
        df2 = @generate df y = sum(x) @if x < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end
end

@testset "Egen with if" begin
    df = DataFrame(x = 1:4, group=["red", "red", "blue", "blue"])
    dfxz = DataFrame(x = 1:4, z = 1:4, group=["red", "red", "blue", "blue"])
    @testset "Constant conditions" begin
        @testset "True" begin
            df2 = @egen df y = sum(x) @if true
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2 < 4
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2+2 == 4
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2+2 == 4 || 2+2 == 5
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2+2 == 5 || 2+2 == 4
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if x < 6 || 2+2 == 5
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2+2 == 5 || x < 6 
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if 2+2 == 4 && x < 6 
            @test all(df2.y .== sum(df.x))
            df2 = @egen df y = sum(x) @if x < 6 && 2+2 == 4
            @test all(df2.y .== sum(df.x))
            df = @egen df y = sum(x) @if group in ["red", "blue"]
            @test all(df.y .== sum(df.x))
            end
        @testset "False" begin
            df2 = @egen df y = sum(x) @if false
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2 > 4
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2+2 != 4
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2+2 == 5 && x <6
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if x < 6 && 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2+2 == 4 && 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2+2 == 5 && 2+2 == 4
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 2+2 == 3 || 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if x > 6 || 2+2 == 5
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if  2+2 == 5 || x > 6
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if group in ["green", "yellow"]
            @test all(df2.y .=== missing)
            end
    end
    @testset "Known conditions" begin
        df2 = @egen df y = sum(x) @if x < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end

    @testset "Condition on other variable" begin
        df2 = @egen dfxz y = sum(x) @if z < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end
    @testset "Window functions operate on subset" begin
        df2 = @egen df y = sum(x) @if x < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end
end

@testset "Summarize" begin
    df = DataFrame(x = 1:1000)
    @testset "Known values" begin
        s = @summarize df x
        @test s.name == :x
        @test s.N == 1000
        @test s.sum_w == 1000
        @test s.mean == 500.5
        @test s.Var ≈ 83416.66666666667
        @test s.sd ≈ 288.8194360957494
        @test s.skewness ≈ 0
        @test s.kurtosis ≈ 1.7999975999976
        @test s.sum == 500500
        @test s.min == 1
        @test s.max == 1000
        @test s.p1 == 10.5
        @test s.p5 == 50.5
        @test s.p10 == 100.5
        @test s.p25 == 250.5
        @test s.p50 == 500.5
        @test s.p75 == 750.5
        @test s.p90 == 900.5
        @test s.p95 == 950.5
        @test s.p99 == 990.5
    end
    @testset "Interpolation" begin
        s = @summarize DataFrame(x=1:11) x
        @test s.name == :x
        @test s.N == 11
        @test s.sum_w == 11
        @test s.mean == 6.0
        @test s.Var ≈ 11.0
        @test s.sd ≈ 3.3166247903554
        @test s.skewness ≈ 0
        @test s.kurtosis ≈ 1.78
        @test s.sum == 66
        @test s.min == 1
        @test s.max == 11
        @test s.p1 ≈ 1.0
        @test s.p5 ≈ 1.05
        @test s.p10 ≈ 1.6
        @test s.p25 ≈ 3.25
        @test s.p50 ≈ 6.0
        @test s.p75 ≈ 8.75
        @test s.p90 ≈ 10.4
        @test s.p95 ≈ 10.95
        @test s.p99 ≈ 11.0
    end

    @testset "If" begin
        df = DataFrame(x = 1:10)
        s = @summarize df x @if x < 5
        @test s.N == 4
        @test s.mean == 2.5
    end

    @testset "Missing values" begin
        df = DataFrame(x = [1, missing, 3])
        s = @summarize df x
        @test s.N == 2
        @test s.mean == 2.0        
    end
end

@testset "Regression" begin
    @testset "Univariate" begin
        # use alternating +1 and -1 as error term to avoid numerical instability
        df = DataFrame(x = 1:10, y = 2 .+ 3 .* (1:10) .+ (-1) .^ (1:10))
        @testset "Known values" begin
            r = @regress df y  x
            @test r.coef ≈ [1.6666666666666679, 3.0606060606060606]
        end
    end
end

@testset "Tabulate" begin
    df = DataFrame(x = [1, 2, 2, 3, 3, 3])
    @testset "Known values" begin
        t = @tabulate df x
        @test :x in t.dimnames
        @test t[1] == 1
        @test t[2] == 2
        @test t[3] == 3
    end

end

# julia> @summarize DataFrame(x=1:11) x
# Kezdi.Summarize(:x, 11, 11.0, 6.0, 11.0, 3.3166247903554, 0.0, -1.22, 66.0, 1.0, 11.0, 1.0, 1.05, 1.6, 3.25, 6.0, 8.75, 10.4, 10.95, 11.0)