# Standalone performance benchmark for Kezdi.jl. This is intentionally NOT part
# of the unit-test suite (`@benchmark` is slow and machine-sensitive). Run it
# manually with:
#
#     julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
#     julia --project=benchmark benchmark/benchmarks.jl

using BenchmarkTools
using Statistics
using Kezdi

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

elapsed = median(t).time / 1e9
println("Median time for 9 @generate log-transforms on 10M x 20: ", elapsed, " s")
