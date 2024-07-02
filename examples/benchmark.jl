using Kezdi
using Random
using Pkg; Pkg.precompile()

df = DataFrame(i = 1:10_000_000)
df.g = rand(0:99, nrow(df))

setdf!(df)

println("Egen")
@time @egen mean_i = mean(i), by(g)
@drop mean_i
@time @egen mean_i = mean(i), by(g)
@drop mean_i

println("Collapse")
@time @collapse mean_i = mean(i), by(g)
setdf!(df)
@time @collapse mean_i = mean(i), by(g)

println("Tabulate")
setdf!(df)
@time @tabulate g
setdf!(df)
@time @tabulate g

println("Summarize")
@time @summarize g
@time @summarize g

println("Regress")
@time @regress i g @if g > 50
@time @regress i g @if g > 50
