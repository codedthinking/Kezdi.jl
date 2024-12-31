using Kezdi
using Plots

df = CSV.read("github-data/data/master/master-table.csv", DataFrame) 
df.C = df.C .+ df[!, "C#"]

setdf(df)

@rename julia Julia
@keep @if Stata > 0 || Matlab > 0 || Python > 0 || R > 0 || Fortran > 0 || C > 0 || Julia > 0
@collapse nStata = sum(Stata) nMatlab = sum(Matlab) nPython = sum(Python) nR = sum(R) nFortran = sum(Fortran) nC = sum(C) nJulia = sum(Julia) pub_start = minimum(zenodo_submission) pub_end = maximum(zenodo_submission) nTotal = length(zenodo_submission)

df = getdf()

# create a bar plot of the number of distinct repos for each language
bars = DataFrame(language = ["Stata", "Matlab", "R", "Python", "Fortran", "Julia"], n = [df.nStata[1], df.nMatlab[1], df.nR[1], df.nPython[1], df.nFortran[1], df.nJulia[1]])

bar_plot = bar(bars.language, bars.n, xlabel="Programming language", ylabel="Number of replication packages", legend=false)
savefig(bar_plot, "languages.png")