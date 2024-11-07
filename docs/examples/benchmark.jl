using Kezdi
using Random
using BenchmarkTools
using Pkg; Pkg.precompile()

df = DataFrame(i = 1:10_000_000)
df.g = rand(0:99, nrow(df))


println("Generate")
setdf(df)
@time @generate ln_i = log(i)
setdf(df)
@time @generate ln_i = log(i)

setdf(df)

println("Replace")
@btime @replace g = 2*i

println("Egen")
@btime @with df  @egen mean_i = mean(i), by(g)

println("Collapse")
@btime @with df  @collapse mean_i = mean(i), by(g)

println("Tabulate")
@btime @with df  @tabulate g

println("Summarize")
@btime @with df  @summarize g

println("Regress")
@btime @with df  @regress i g @if g > 50
