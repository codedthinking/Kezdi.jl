using Kezdi
using Random
using Pkg; Pkg.precompile()

df = DataFrame(i = 1:10_000_000)
df.g = rand(0:99, nrow(df))

@time @egen df mean_i = mean(i), by(g)
@time @egen df mean_i = mean(i), by(g)

@time @collapse df mean_i = mean(i), by(g)
@time @collapse df mean_i = mean(i), by(g)

@time @tabulate df g
@time @tabulate df g

@time @summarize df g
@time @summarize df g

@time @regress df i g @if g > 50
@time @regress df i g @if g > 50
