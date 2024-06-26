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

    @testset "Lists-valued variables" begin
        df = DataFrame(x = [[1, 2], [3, 4], [5, 6], [7, 8]])
        @test (@generate df x1 = getindex(x, 1)).x1 == [1, 3, 5, 7]
        @test (@generate df x2 = getindex(x, 2)).x2 == [2, 4, 6, 8]
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

    @testset "Count function" begin
        df = DataFrame(x = [1, 2, 2, missing, 3, 3])
        df2 = @collapse df y = rowcount(x)
        @test df2.y == [5]
        df2 = @collapse df y = rowcount(distinct(x))
        @test df2.y == [3]
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
        @test df2.y == [4, 2, 4, 4, 11, 11]
        df2 = @egen df y = minimum(x), by(group, s)
        @test df2.y == [1, 2, 1, 4, 5, 5]
        df2 = @egen df y = maximum(x), by(group, s)
        @test df2.y == [3, 2, 3, 4, 6, 6]
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
    df2 = @drop df @if a < 3
    @test "a" in names(df2)
    @test "b" in names(df2)
    @test nrow(df2) == 2
    @test all(df2.a .== [3, 4])
    @test all(df2.b .== [7, 8])
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

@testset "x in list" begin
    df = DataFrame(x = 1:4, group=["red", "red", "blue", "blue"])
    dfxz = DataFrame(x = 1:4, z = 1:4, group=["red", "red", "blue", "blue"])
    df2 = @generate df y = sum(x) @if group in [["red", "blue"]]
    @test all(df2.y .== sum(df.x))
    df2 = @generate df y = sum(x) @if group in [["green", "yellow"]]
    @test all(df2.y .=== missing)
    df2 = @generate dfxz y = sum(x) @if z == 4 && group in [["blue"]]
    @test all(df2.y .=== [missing, missing, missing, 4])
    df2 = @generate dfxz y = sum(x) @if x == 4 && group in [["blue"]] && z > 2
    @test all(df2.y .=== [missing, missing, missing, 4])
    df2 = @generate dfxz y = sum(x) @if x == 4 && group in [["blue"]] && z > 2 && z < 5
    @test all(df2.y .=== [missing, missing, missing, 4])
    df2 = @generate dfxz y = sum(x) @if x == 4 && group in [["blue"]] && z > 2 && z < 5 || z < 0
        @test all(df2.y .=== [missing, missing, missing, 4])
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
            end
    end
    @testset "Known conditions" begin
        df2 = @egen df y = sum(x) @if x < 3
        @test all(df2.y .=== [3, 3, missing, missing])
        df2 = @egen df y = sum(x) @if group in [["blue"]]
        @test all(df2.y .=== [missing, missing, 7, 7])
    end

    @testset "Condition on other variable" begin
        df2 = @egen dfxz y = sum(x) @if z < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end
    @testset "Window functions operate on subset" begin
        df2 = @egen df y = sum(x) @if x < 3
        @test all(df2.y .=== [3, 3, missing, missing])
    end
    @testset "Complex conditions" begin
        df2 = @egen dfxz y = sum(x) @if z == 4 && x > 2
        @test all(df2.y .=== [missing, missing, missing, 4])
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

@testset "Boolean-valued column" begin
    df = DataFrame(x=1:4, z=[true, false, true, false])
    s = @summarize df x @if z
    @test s.N == 2
    @test s.mean == 2.0
end

@testset "Regression" begin
    @testset "Univariate" begin
        # use alternating +1 and -1 as error term to avoid numerical instability
        df = DataFrame(x = 1:10, y = 2 .+ 3 .* (1:10) .+ (-1) .^ (1:10))
        @testset "Known values" begin
            r = @regress df y 1
            @test r.coef ≈ [18.5]
            r = @regress df y x
            @test r.coef ≈ [1.6666666666666679, 3.0606060606060606]
            r = @regress df y -x
            @test r.coef ≈ [1.6666666666666679, -3.0606060606060606]
            r = @regress df y x/10
            @test r.coef ≈ [1.6666666666666679, 30.606060606060606]
            r = @regress df -y x/10
            @test r.coef ≈ [-1.6666666666666679, -30.606060606060606]
            r = @regress df -y -x/10
            @test r.coef ≈ [-1.6666666666666679, 30.606060606060606]
        end
        @testset "Conditions" begin
            r = @regress df y x @if x < 5
            @test r.coef ≈ [1.0, 3.4000000000000004]
            r = @regress df y x @if x < 5 || x > 8 
            @test r.coef ≈ [1.795294117647062, 3.0423529411764703]
        end
    end
    @testset "Multivariate" begin
        df = DataFrame(x = 1:10, y = 2 .+ 3 .* (1:10) .+ (-1) .^ (1:10), z = (-1) .^ (1:10), s = ["a", "a", "a", "a", "b", "b", "b", "b", "c", "c"])
        @testset "Known values" begin
            r = @regress df y x z fe(s)
            @test r.coef ≈ [2.9999999999999996, 1.0000000000000002]
            r = @regress df y x z 
            @test r.coef ≈ [2.0000000000000013, 3.0, 1.0]
            r = @regress df y x z z*x fe(s)
            @test r.coef ≈ [2.9999999999999996, 1.0000000000000002, 0.0]
            r = @regress df y x z z*x
            @test r.coef ≈ [2.0000000000000013, 3.0, 1.0000000000000004, -8.881784197001259e-17]
        end
        @testset "Conditions" begin
            r = @regress df y x z fe(s) @if x < 5
            @test r.coef ≈ [ 3.0000000000000004, 0.9999999999999998]
            r = @regress df y x z @if x < 5
            @test r.coef ≈ [1.9999999999999998, 3.0000000000000004, 0.9999999999999998]
            r = @regress df y x z z*x fe(s) @if x < 5
            @test r.coef ≈ [3.0000000000000004, 0.9999999999999987, 4.440892098500626e-16]
            r = @regress df y x z z*x @if x < 5
            @test r.coef ≈ [1.9999999999999996, 3.0000000000000004, 0.9999999999999987, 4.440892098500626e-16]
            r = @regress df y x z fe(s) @if x < 5 || x >8
            @test r.coef ≈ [3.0, 1.0]
            r = @regress df y x z @if x < 5 || x >8
            @test r.coef ≈ [2.000000000000003, 2.9999999999999996, 1.0]
            r = @regress df y x z z*x fe(s) @if x < 5 || x >8
            @test r.coef ≈ [3.0, 1.0000000000000002, -5.1241062675007215e-17]
            r = @regress df y x z z*x @if x < 5 || x >8
            @test r.coef ≈ [2.000000000000003, 2.9999999999999996, 0.9999999999999998, 5.124106267500724e-17]
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
    df = DataFrame(x = [1, 2, 2, 3, 3, 3], y = [0, 0, 0, 1, 1, 1])
    @testset "Twoway" begin
        t = @tabulate df x y
        @test :x in t.dimnames
        @test :y in t.dimnames
        @test sum(t) == nrow(df)
        @test t[1, 1] == 1
        @test t[2, 1] == 2
        @test t[3, 2] == 3
    end
end

@testset "Count" begin
    df = DataFrame(x = 1:10, y = 2 .+ 3 .* (1:10) .+ (-1) .^ (1:10), z = (-1) .^ (1:10), s = ["a", "a", "a", "a", "b", "b", "b", "b", "c", "c"])
    @testset "Known values" begin
        c = @count df
        @test c == 10
        c = @count df @if s == "a"
        @test c == 4
        c = @count df @if s == "b" && x < 5
        @test c == 0
        c = @count df, by(s)
        @test c == [4, 4, 2]
        c = @count df, by(s, z)
        @test c == [2,2,2,2,1,1]
    end
end

@testset "Use" begin
    using DataFrames
    using ReadStatTables
    df = readstat("test.dta") |> DataFrame
    @testset "Known values" begin
        @test df == @use "test.dta"
    end
end

@testset "Sort" begin
    df = DataFrame(x = [1, 2, 3, 2, 1, 3], y = [0, 2, 0, 1, 1, 1])
    @testset "Known values" begin
        df2 = @sort df x
        @test all(df2.x .== [1, 1, 2, 2, 3, 3])
        df2 = @sort df x y
        @test all(df2.x .== [1, 1, 2, 2, 3, 3])
        @test all(df2.y .== [0, 1, 1, 2, 0, 1])
    end
    @testset "Reverse" begin
        df2 = @sort df x, desc
        @test all(df2.x .== [3, 3, 2, 2, 1, 1])
        df2 = @sort df x y,  desc
        @test all(df2.x .== [3, 3, 2, 2, 1, 1])
        @test all(df2.y .== [1, 0, 2, 1, 1, 0])
    end
    @testset "Missing values" begin
        df = DataFrame(x = [1, 2, missing, 3, 3, 3], y = [0, 0, 0, 1, 1, 1])
        df2 = @sort df x
        #@test all(df2.x .== [1, 2, 3, 3, 3, missing])
        df2 = @sort df x y
        #@test all(df2.x .== [1, 2, 3, 3, 3, missing])
        @test all(df2.y .== [0, 0, 1, 1, 1, 0])
    end
end

@testset "Order" begin
    df = DataFrame(x = 1:5, z = (-1) .^ (1:5), y = 2 .+ 3 .* (1:5) .+ (-1) .^ (1:5), s = ["a", "a", "a", "b", "c"])
    df2 = @order df 
    @test names(df2) == names(df)
    df2 = @order df, alphabetical
    @test names(df2) == sort(names(df), rev = false)
    df2 = @order df, alphabetical desc
    @test names(df2) == sort(names(df), rev = true)
    df2 = @order df s
    @test names(df2) == ["s","x","z","y"]
    df2 = @order df s, alphabetical
    @test names(df2) == ["s","x","y","z"]
    df2 = @order df s, alphabetical last
    @test names(df2) == ["x","y","z","s"]
    df2 = @order df s, alphabetical desc
    @test names(df2) == ["s","z","y","x"]
    df2 = @order df s, alphabetical desc last
    @test names(df2) == ["z","y","x","s"]
    df2 = @order df s, after(z)
    @test names(df2) == ["x","z","s","y"]
    df2 = @order df s, after(z) alphabetical
    @test names(df2) == ["x","y","z","s"]
    df2 = @order df s, after(z) alphabetical desc
    @test names(df2) == ["z","s","y","x"]
    df2 = @order df s, before(y)
    @test names(df2) == ["x","z","s","y"]
    df2 = @order df s, before(y) alphabetical
    @test names(df2) == ["x","s","y","z"]
    df2 = @order df s, before(y) alphabetical desc
    @test names(df2) == ["z","s","y","x"]

end