using Kezdi

begin
    N = 20_000_000
    K = 20
    df = DataFrame(rand(N, K), :auto)
    @time @with df begin
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
    # 43.221702 seconds (154.87 k allocations: 37.859 GiB, 27.68% gc time, 0.47% compilation time)
end