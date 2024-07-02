@testset "Using @with and Kezdi.jl macros" begin
    df = DataFrame(x = 1:10, 
        y = 2 .+ 3 .* (1:10) .+ (-1) .^ (1:10), 
        z = (-1) .^ (1:10), 
        s = ["a", "a", "a", "a", "b", "b", "b", "b", "c", "c"])

    @testset "Check @with and @with! are the same" begin
        df2 = @with df begin
            @generate c = 1 ^ _n
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            @regress y x z c
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            @regress y x z c 
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            r = @regress y x z c
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            r = @regress y x z c 
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            @tabulate y x z c
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            @tabulate y x z c 
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            t = @tabulate y x z c
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            t = @tabulate y x z c 
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            @summarize x
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            @summarize x
            @keep @if x<6
        end
        @test df2 == df3

        df2 = @with df begin
            @generate c = 1 ^ _n
            s = @summarize x
            @keep @if x<6
        end
        df3 = copy(df)
        @with! df3 begin
            @generate c = 1 ^ _n
            s = @summarize x
            @keep @if x<6
        end
        @test df2 == df3
    end

    @testset "Check aside functionalities" begin
        @testset "Summarize" begin
            @testset "Known values" begin
                @with df begin 
                    @generate c = 1 ^ _n
                    s = @summarize x
                    @keep @if x<6
                end
                @test s.N == 10
                @test s.mean == 5.5
            end
        
            @testset "If" begin
                @with df begin 
                    @generate c = 1 ^ _n
                    s = @summarize x @if s == "a"
                    @keep @if x<6
                end
                @test s.N == 4
                @test s.mean == 2.5
            end
        end

        @testset "Tabulate" begin
            @testset "Known values" begin
                df2 = @with df begin 
                    @generate c = 1 ^ _n
                    t = @tabulate c x
                end
                @test t == freqtable(df2, :c, :x)
            end
        
            @testset "If" begin
                df2 = @with df begin 
                    @generate c = 1 ^ _n
                    t = @tabulate c x @if s == "a"
                end
                @test t == freqtable(filter(row -> row.s == "a", df2), :c, :x)
            end
        end

        @testset "Regress" begin
            @testset "Known values" begin
                df2 = @with df begin 
                    @generate c = 1 ^ _n
                    r = @regress y x c
                end
                r2 = reg(df2, @formula(y ~ x + c))
                @test r.coef ≈ r2.coef
                @test r.coefnames == r2.coefnames
            end
        
            @testset "If" begin
                df2 = @with df begin 
                    @generate c = 1 ^ _n
                    r = @regress y x c @if s == "a"
                end
                r2 = reg(filter(row -> row.s == "a", df2), @formula(y ~ x + c))
                @test r.coef ≈ r2.coef
                @test r.coefnames == r2.coefnames
            end
        end

    end
end
