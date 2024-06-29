using Test


@testset "1" begin
    x = [1, 2, 3]
    # one symbol
    y = @with x begin
        sum
    end
    @test y == sum(x)

    # two expressions
    z = @with x begin
        *(3)
        sum
    end
    @test z == sum(x .* 3)

end

@testset "No begin" begin
    x = [1, 2, 3]
    y = @with x sum
    @test y == 6

    f() = 1
    y = @with f() first
    @test y == 1

    y = @with 1 (t -> t + 1)()
    @test y == 2

    y = @with 1 (==(2))
    @test y == false

    y = @with 1 (==(2)) first (==(false))
    @test y == true

end

@testset "Invalid invocations" begin
    # let block
    @test_throws LoadError eval(quote
        @with [1, 2, 3] let
            sum
        end
    end)
end

@testset "Broadcast macro symbol" begin
    x = 1:5
    y = @with x begin
        @. sin
        sum
    end
    @test y == sum(sin.(x))

end

macro sin(exp)
    :(sin($(esc(exp))))
end

macro broadcastminus(exp1, exp2)
    :(broadcast(-, $(esc(exp1)), $(esc(exp2))))
end

@testset "Splicing into macro calls" begin

    x = 1
    y = @with x begin
        @sin
    end
    @test y == sin(x)

    y = @with x begin
        @sin()
    end
    @test y == sin(x)

    xx = [1, 2, 3, 4]
    yy = @with xx begin
        @broadcastminus(2.5)
    end
    @test yy == broadcast(-, xx, 2.5)

end

@testset "Single arg version" begin
    x = [1, 2, 3]

    xx = @with begin
        x
    end
    @test xx == x

    # this has a different internal structure (one LineNumberNode missing I think)
    @test x == @with begin
        x
    end

    @test sum(x) == @with begin
        x
        sum
    end

    y = @with begin
        x
        sum
    end
    @test y == sum(x)

    z = @with begin
        x
        @. sqrt
        sum
    end
    @test z == sum(sqrt.(x))

    @test sum == @with begin
        sum
    end
end

@testset "Invalid single arg versions" begin
    # empty
    if !(VERSION < v"1.1") # weird interaction with test macros in 1.0
        @test_throws LoadError eval(quote
            @with begin
            end
        end)
    end

end

@testset "Handling keyword argments" begin
    f(a; kwarg) = (a, kwarg)
    @test (:a, :kwarg) == @with begin
        :a
        f(kwarg = :kwarg)
    end
    @test (:a, :kwarg) == @with begin
        :a
        f(; kwarg = :kwarg)
    end
end

# issue 13
@testset "No argument call" begin
    x = 1
    y = @with x begin
        sin()
    end
    @test y == sin(x)
end

# issue 13
@testset "Broadcasting calls" begin

    xs = [1, 2, 3]
    ys = @with xs begin
        sin.()
    end
    @test ys == sin.(xs)

    add(x, y) = x + y

    zs = [4, 5, 6]
    sums = @with xs begin
        add.(zs)
    end
    @test sums == add.(xs, zs)
end

# issue 16
@testset "Empty with" begin
    a = 2
    x = @with a + 1 begin
    end
    @test x == 3

    y = @with begin
        a + 1
    end
    @test y == 3
end

module LocalModule
    function square(xs)
        xs .^ 2
    end

    function power(xs, pow)
        xs .^ pow
    end

    add_one(x) = x + 1

    macro sin(exp)
        :(sin($(esc(exp))))
    end

    macro broadcastminus(exp1, exp2)
        :(broadcast(-, $(esc(exp1)), $(esc(exp2))))
    end

    module SubModule
        function square(xs)
            xs .^ 2
        end

        function power(xs, pow)
            xs .^ pow
        end

        add_one(x) = x + 1

        macro sin(exp)
            :(sin($(esc(exp))))
        end

        macro broadcastminus(exp1, exp2)
            :(broadcast(-, $(esc(exp1)), $(esc(exp2))))
        end
    end
end

@testset "Module qualification" begin

    using .LocalModule

    xs = [1, 2, 3]
    pow = 4
    y = @with xs begin
        LocalModule.square
        LocalModule.power(pow)
        Base.sum
    end
    @test y == sum(LocalModule.power(LocalModule.square(xs), pow))

    y2 = @with xs begin
        LocalModule.SubModule.square
        LocalModule.SubModule.power(pow)
        Base.sum
    end
    @test y2 == sum(LocalModule.SubModule.power(LocalModule.SubModule.square(xs), pow))

    y3 = @with xs begin
        @. LocalModule.add_one
        @. LocalModule.SubModule.add_one
    end
    @test y3 == LocalModule.SubModule.add_one.(LocalModule.add_one.(xs))

    y4 = @with xs begin
        LocalModule.@broadcastminus(2.5)
    end
    @test y4 == LocalModule.@broadcastminus(xs, 2.5)

    y5 = @with xs begin
        LocalModule.SubModule.@broadcastminus(2.5)
    end
    @test y5 == LocalModule.SubModule.@broadcastminus(xs, 2.5)

    y6 = @with 3 begin
        LocalModule.@sin
    end
    @test y6 == LocalModule.@sin(3)

    y7 = @with 3 begin
        LocalModule.SubModule.@sin
    end
    @test y7 == LocalModule.SubModule.@sin(3)
end

function kwfunc(y; x = 1)
    y * x
end

macro kwmac(exprs...)
    :(kwfunc($(esc.(exprs)...)))
end

@testset "Keyword arguments" begin
    
    @test 6 == @with 2 begin
        kwfunc(; x = 3)
    end

    @test 6 == @with 2 begin
        @kwmac(; x = 3)
    end
end

@testset "Workaround for docstring parsing" begin
    @test "hi" == @with " hi " strip
    @test "hi" == @with " hi " begin
        strip
    end
    @test "hi" == @with begin
        " hi "
        strip
    end
end

@testset "Variable assignment syntax" begin
    result = @with 1:10 begin
        x = sqrt.()
        y = sum
        sqrt
    end
    @test x == sqrt.(1:10)
    @test y == sum(x)
    @test result == sqrt(y)
end

module TestModule
    using Kezdi
end

@testset "No variable leaks" begin
    
    allnames() = Set(names(TestModule, all = true))
    _names = allnames()

    TestModule.eval(quote
        @with 1:10 begin
            sum
            sqrt
        end
    end)

    @test setdiff(allnames(), _names) == Set()

    TestModule.eval(quote
        @with begin
            1:10
            sum
            sqrt
        end
    end)

    @test setdiff(allnames(), _names) == Set()

    TestModule.eval(quote
        @with begin
            1:10
            x = sum
            y = sqrt
        end
    end)

    @test setdiff(allnames(), _names) == Set([:x, :y])
end

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
