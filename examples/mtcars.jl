using Kezdi
using RDatasets

df = dataset("datasets", "mtcars")

renamed_df = @with df begin
    @rename HP Horsepower
    @rename Disp Displacement
    @rename WT Weight
    @rename Cyl Cylinders
end

get_make(text) = split(text, " ")[1]

function geometric_mean(x::AbstractVector)
    n = length(x)
    return exp(sum(log.(x)) / n)
end

@with renamed_df begin
    @tabulate Gear
    @keep @if Gear == 4
    @keep Model MPG Horsepower Weight Displacement Cylinders
    @summarize MPG
    @regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust 
    @generate Make = Main.get_make(Model)
    @tabulate Make
    @collapse geom_NPG = Main.geometric_mean(MPG), by(Make)
    @list
end
