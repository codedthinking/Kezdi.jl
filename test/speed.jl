@testset "Generate completes within 10 seconds" begin
    df = DataFrame(rand(10_000_000, 20), :auto)

    t = @benchmark let df = $df
        @with df begin
            @generate ln_x1 = log(x1)
            @generate ln_x2 = log(x2)
            @generate ln_x3 = log(x3)
            @generate ln_x4 = log(x4)
            @generate ln_x5 = log(x5)
            @generate ln_x6 = log(x6)
            @generate ln_x7 = log(x7)
            @generate ln_x8 = log(x8)
            @generate ln_x9 = log(x9)
        end
    end

    time = median(t).time / 1e9
    @test time < 10.0
end
