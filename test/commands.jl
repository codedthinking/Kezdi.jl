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

    @testset "Error handling" begin
        @test_throws ArgumentError @generate df x = 1
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
        @test_throws ArgumentError @replace df y = 1
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
            end
        @testset "False" begin
            df2 = @generate df y = x @if false
            @test all(df2.y .=== missing)
            df2 = @generate df y = x @if 1 == 0
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

@testset "Egen" begin
    df = DataFrame(x = 1:4, s = ["a", "b", "c", "d"], group = ["red", "red", "blue", "blue"])

    @testset "Column added" begin
        df2 = @egen df y = mean(x)
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
    @testset "Known values by group" begin
        df2 = @egen df y = sum(x) @by group
        @test all(df2.y .== [3, 3, 7, 7])
        df2 = @egen df y = minimum(x) @by group
        @test all(df2.y .== [1, 1, 3, 3])
        df2 = @egen df y = maximum(x) @by group
        @test all(df2.y .== [2, 2, 4, 4])
    end
    @testset "Error handling" begin
        @test_throws ArgumentError @egen df x = 1
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
            end
        @testset "False" begin
            df2 = @egen df y = sum(x) @if false
            @test all(df2.y .=== missing)
            df2 = @egen df y = sum(x) @if 1 == 0
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