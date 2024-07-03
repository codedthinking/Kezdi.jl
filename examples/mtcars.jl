using Kezdi
using RDatasets

df = dataset("datasets", "mtcars")

renamed_df = @with df begin
    @rename HP Horsepower
    @rename Disp Displacement
    @rename WT Weight
    @rename Cyl Cylinders
end

@with renamed_df begin
    @tabulate Gear
    @keep @if Gear == 4
    @keep MPG Horsepower Weight Displacement Cylinders
    @summarize MPG
    @regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust 
end
