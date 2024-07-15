var documenterSearchIndex = {"docs":
[{"location":"reference/","page":"Reference","title":"Reference","text":"CurrentModule = Kezdi","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"Modules = [Kezdi]","category":"page"},{"location":"reference/#Kezdi.Kezdi","page":"Reference","title":"Kezdi.Kezdi","text":"Kezdi.jl is a Julia package for data manipulation and analysis. It is inspired by Stata, but it is written in Julia, which makes it faster and more flexible. It is designed to be used in the Julia REPL, but it can also be used in Jupyter notebooks or in scripts.\n\n\n\n\n\n","category":"module"},{"location":"reference/#Base.ismissing-Tuple","page":"Reference","title":"Base.ismissing","text":"ismissing(args...) -> Bool\n\nReturn true if any of the arguments is missing.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.DNV-Tuple","page":"Reference","title":"Kezdi.DNV","text":"DNV(f(x))\n\nIndicate that the function f should not be vectorized. The name DNV is only used for parsing, do not call it directly.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.distinct-Tuple{AbstractVector}","page":"Reference","title":"Kezdi.distinct","text":"distinct(x::AbstractVector) = unique(x)\n\nConvenience function to get the distinct values of a vector.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.getdf-Tuple{}","page":"Reference","title":"Kezdi.getdf","text":"getdf() -> AbstractDataFrame\n\nReturn the global data frame.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.keep_only_values-Tuple{Any}","page":"Reference","title":"Kezdi.keep_only_values","text":"keep_only_values(x::AbstractVector) -> AbstractVector\n\nReturn a vector with only the values of x, excluding any missingvalues,nothings,Infa andNaN`s.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.rowcount-Tuple{AbstractVector}","page":"Reference","title":"Kezdi.rowcount","text":"rowcount(x::AbstractVector) = length(keep_only_values(x))\n\nCount the number of valid values in a vector.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.setdf-Tuple{Union{Nothing, AbstractDataFrame}}","page":"Reference","title":"Kezdi.setdf","text":"setdf(df::Union{AbstractDataFrame, Nothing})\n\nSet the global data frame.\n\n\n\n\n\n","category":"method"},{"location":"reference/#Kezdi.@collapse-Tuple","page":"Reference","title":"Kezdi.@collapse","text":"@collapse y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nCollapse df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@count-Tuple","page":"Reference","title":"Kezdi.@count","text":"@count if condition]\n\nCount the number of rows for which the condition is true. If condition is not provided, the total number of rows is counted.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@drop-Tuple","page":"Reference","title":"Kezdi.@drop","text":"@drop y1 y2 ...\n\nor     @drop if condition]    \n\nDrop the variables y1, y2, etc. from df. If condition is provided, the rows for which the condition is true are dropped.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@egen-Tuple","page":"Reference","title":"Kezdi.@egen","text":"@egen y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nGenerate new variables in df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@generate-Tuple","page":"Reference","title":"Kezdi.@generate","text":"@generate y = expr [@if condition]\n\nCreate a new variable y in df by evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. \n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@head","page":"Reference","title":"Kezdi.@head","text":"@head [n]\n\nDisplay the first n rows of the data frame. By default, n is 5.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@keep-Tuple","page":"Reference","title":"Kezdi.@keep","text":"@keep y1 y2 ... [@if condition]\n\nKeep only the variables y1, y2, etc. in df. If condition is provided, only the rows for which the condition is true are kept.  \n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@list-Tuple","page":"Reference","title":"Kezdi.@list","text":"@list [@if condition]\n\nDisplay the entire data frame or the rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@names-Tuple{}","page":"Reference","title":"Kezdi.@names","text":"@names\n\nDisplay the names of the variables in the data frame.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@order-Tuple","page":"Reference","title":"Kezdi.@order","text":"@order y1 y2 ... [desc] [last] [after=var] [before=var] [alphabetical]\n\nReorder the variables y1, y2, etc. in the data frame. By default, the variables are ordered in the order they are listed. If desc is provided, the variables are ordered in descending order. If last is provided, the variables are moved to the end of the data frame. If after is provided, the variables are moved after the variable var. If before is provided, the variables are moved before the variable var. If alphabetical is provided, the variables are ordered alphabetically.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@regress-Tuple","page":"Reference","title":"Kezdi.@regress","text":"@regress y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]\n\nEstimate a regression model in df with dependent variable y and independent variables x1, x2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If robust is provided, robust standard errors are calculated. If cluster is provided, clustered standard errors are calculated.\n\nThe regression is limited to rows for which all variables are values. Missing values, infinity, and NaN are automatically excluded.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@rename-Tuple","page":"Reference","title":"Kezdi.@rename","text":"@rename oldname newname\n\nRename the variable oldname to newname in the data frame.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@replace-Tuple","page":"Reference","title":"Kezdi.@replace","text":"@replace y = expr [@if condition]\n\nReplace the values of y in df with the result of evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@sort-Tuple","page":"Reference","title":"Kezdi.@sort","text":"@sort y1 y2 ...[, desc]\n\nSort the data frame by the variables y1, y2, etc. By default, the variables are sorted in ascending order. If desc is provided, the variables are sorted in descending order\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@summarize-Tuple","page":"Reference","title":"Kezdi.@summarize","text":"@summarize y [@if condition]\n\nSummarize the variable y in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@tabulate-Tuple","page":"Reference","title":"Kezdi.@tabulate","text":"@tabulate y1 y2 ... [@if condition]\n\nCreate a frequency table for the variables y1, y2, etc. in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@tail","page":"Reference","title":"Kezdi.@tail","text":"@tail [n]\n\nDisplay the last n rows of the data frame. By default, n is 5.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@use-Tuple{Any}","page":"Reference","title":"Kezdi.@use","text":"@use \"filename.dta\"\n\nRead the data from the file filename.dta and set it as the global data frame.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = Kezdi","category":"page"},{"location":"#Kezdi.jl-Documentation","page":"Home","title":"Kezdi.jl Documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Kezdi.jl is a Julia package that provides a Stata-like interface for data manipulation and analysis. It is designed to be easy to use for Stata users who are transitioning to Julia.[stata] ","category":"page"},{"location":"","page":"Home","title":"Home","text":"It imports and reexports CSV, DataFrames, FixedEffectModels, FreqTables, ReadStatTables, Statistics, and StatsBase. These packages are not covered in this documentation, but you can find more information by following the links.","category":"page"},{"location":"#Getting-started","page":"Home","title":"Getting started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"warning: Kezdi.jl is in beta\nKezdi.jl is currently in beta. We have more than 300 unit tests and a large code coverage. (Image: Coverage) The package, however, is not guaranteed to be bug-free. If you encounter any issues, please report them as a GitHub issue.If you would like to receive updates on the package, please star the repository on GitHub and sign up for email notifications here.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To install the package, run the following command in Julia's REPL:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg; Pkg.add(\"Kezdi\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"Every Kezdi.jl command is a macro that begins with @. These commands operate on a global DataFrame that is set using the setdf function. Alternatively, commands can be executed within a @with block that sets the DataFrame for the duration of the block.","category":"page"},{"location":"#Example","page":"Home","title":"Example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Kezdi\nusing RDatasets\n\ndf = dataset(\"datasets\", \"mtcars\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"setdf(df)\n\n@rename HP Horsepower\n@rename Disp Displacement\n@rename WT Weight\n@rename Cyl Cylinders\n\n@tabulate Gear\n@keep @if Gear == 4\n@keep MPG Horsepower Weight Displacement Cylinders\n@summarize MPG\n@regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Alternatively, you can use the @with block to avoid writing to a global DataFrame:","category":"page"},{"location":"","page":"Home","title":"Home","text":"renamed_df = @with df begin\n    @rename HP Horsepower\n    @rename Disp Displacement\n    @rename WT Weight\n    @rename Cyl Cylinders\nend\n\n@with renamed_df begin\n    @tabulate Gear\n    @keep @if Gear == 4\n    @keep MPG Horsepower Weight Displacement Cylinders\n    @summarize MPG\n    @regress log(MPG) log(Horsepower) log(Weight) log(Displacement) fe(Cylinders), robust \nend","category":"page"},{"location":"#Benefits-of-using-Kezdi.jl","page":"Home","title":"Benefits of using Kezdi.jl","text":"","category":"section"},{"location":"#Free-and-open-source","page":"Home","title":"Free and open-source","text":"","category":"section"},{"location":"#Speed","page":"Home","title":"Speed","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Command Stata Julia 1st run Julia 2nd run Speedup\n@egen 4.90s 1.36s 0.36s 14x\n@collapse 0.92s 0.39s 0.28s 3x\n@tabulate 2.14s 0.68s 0.09s 24x\n@summarize 10.40s 0.58s 0.36s 29x\n@regress 0.89s 1.95s 0.11s 8x","category":"page"},{"location":"","page":"Home","title":"Home","text":"See the benchmarking code for Stata and Kezdi.jl.","category":"page"},{"location":"#Use-any-Julia-function","page":"Home","title":"Use any Julia function","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@generate logHP = log(Horsepower)","category":"page"},{"location":"#Easily-extendable-with-user-defined-functions","page":"Home","title":"Easily extendable with user-defined functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The function can operate on individual elements,","category":"page"},{"location":"","page":"Home","title":"Home","text":"get_make(text) = split(text, \" \")[1]\n@generate Make = get_make(Model)","category":"page"},{"location":"","page":"Home","title":"Home","text":"or on the entire column:","category":"page"},{"location":"","page":"Home","title":"Home","text":"function geometric_mean(x::Vector)\n    n = length(x)\n    return exp(sum(log.(x)) / n)\nend\n@collapse geom_NPG = geometric_mean(MPG), by(Cylinders)","category":"page"},{"location":"#Commands","page":"Home","title":"Commands","text":"","category":"section"},{"location":"#Setting-and-inspecting-the-global-DataFrame","page":"Home","title":"Setting and inspecting the global DataFrame","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"setdf","category":"page"},{"location":"#Kezdi.setdf","page":"Home","title":"Kezdi.setdf","text":"setdf(df::Union{AbstractDataFrame, Nothing})\n\nSet the global data frame.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"getdf","category":"page"},{"location":"#Kezdi.getdf","page":"Home","title":"Kezdi.getdf","text":"getdf() -> AbstractDataFrame\n\nReturn the global data frame.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"@names","category":"page"},{"location":"#Kezdi.@names","page":"Home","title":"Kezdi.@names","text":"@names\n\nDisplay the names of the variables in the data frame.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@list","category":"page"},{"location":"#Kezdi.@list","page":"Home","title":"Kezdi.@list","text":"@list [@if condition]\n\nDisplay the entire data frame or the rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@head","category":"page"},{"location":"#Kezdi.@head","page":"Home","title":"Kezdi.@head","text":"@head [n]\n\nDisplay the first n rows of the data frame. By default, n is 5.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@tail","category":"page"},{"location":"#Kezdi.@tail","page":"Home","title":"Kezdi.@tail","text":"@tail [n]\n\nDisplay the last n rows of the data frame. By default, n is 5.\n\n\n\n\n\n","category":"macro"},{"location":"#Filtering-columns-and-rows","page":"Home","title":"Filtering columns and rows","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@keep","category":"page"},{"location":"#Kezdi.@keep","page":"Home","title":"Kezdi.@keep","text":"@keep y1 y2 ... [@if condition]\n\nKeep only the variables y1, y2, etc. in df. If condition is provided, only the rows for which the condition is true are kept.  \n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@drop","category":"page"},{"location":"#Kezdi.@drop","page":"Home","title":"Kezdi.@drop","text":"@drop y1 y2 ...\n\nor     @drop if condition]    \n\nDrop the variables y1, y2, etc. from df. If condition is provided, the rows for which the condition is true are dropped.\n\n\n\n\n\n","category":"macro"},{"location":"#Modifying-the-data","page":"Home","title":"Modifying the data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@rename","category":"page"},{"location":"#Kezdi.@rename","page":"Home","title":"Kezdi.@rename","text":"@rename oldname newname\n\nRename the variable oldname to newname in the data frame.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@generate","category":"page"},{"location":"#Kezdi.@generate","page":"Home","title":"Kezdi.@generate","text":"@generate y = expr [@if condition]\n\nCreate a new variable y in df by evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. \n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@replace","category":"page"},{"location":"#Kezdi.@replace","page":"Home","title":"Kezdi.@replace","text":"@replace y = expr [@if condition]\n\nReplace the values of y in df with the result of evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@egen","category":"page"},{"location":"#Kezdi.@egen","page":"Home","title":"Kezdi.@egen","text":"@egen y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nGenerate new variables in df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@collapse","category":"page"},{"location":"#Kezdi.@collapse","page":"Home","title":"Kezdi.@collapse","text":"@collapse y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nCollapse df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@sort","category":"page"},{"location":"#Kezdi.@sort","page":"Home","title":"Kezdi.@sort","text":"@sort y1 y2 ...[, desc]\n\nSort the data frame by the variables y1, y2, etc. By default, the variables are sorted in ascending order. If desc is provided, the variables are sorted in descending order\n\n\n\n\n\n","category":"macro"},{"location":"#Summarizing-and-analyzing-data","page":"Home","title":"Summarizing and analyzing data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@count","category":"page"},{"location":"#Kezdi.@count","page":"Home","title":"Kezdi.@count","text":"@count if condition]\n\nCount the number of rows for which the condition is true. If condition is not provided, the total number of rows is counted.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@tabulate","category":"page"},{"location":"#Kezdi.@tabulate","page":"Home","title":"Kezdi.@tabulate","text":"@tabulate y1 y2 ... [@if condition]\n\nCreate a frequency table for the variables y1, y2, etc. in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@summarize","category":"page"},{"location":"#Kezdi.@summarize","page":"Home","title":"Kezdi.@summarize","text":"@summarize y [@if condition]\n\nSummarize the variable y in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@regress","category":"page"},{"location":"#Kezdi.@regress","page":"Home","title":"Kezdi.@regress","text":"@regress y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]\n\nEstimate a regression model in df with dependent variable y and independent variables x1, x2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If robust is provided, robust standard errors are calculated. If cluster is provided, clustered standard errors are calculated.\n\nThe regression is limited to rows for which all variables are values. Missing values, infinity, and NaN are automatically excluded.\n\n\n\n\n\n","category":"macro"},{"location":"#Use-on-another-DataFrame","page":"Home","title":"Use on another DataFrame","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@with","category":"page"},{"location":"#Kezdi.With.@with","page":"Home","title":"Kezdi.With.@with","text":"@with df begin\n    # do something with df\nend\n\nThe @with macro is a convenience macro that allows you to set the current data frame and perform operations on it in a single block. The first argument is the data frame to set as the current data frame, and the second argument is a block of code to execute. The data frame is set as the current data frame for the duration of the block, and then restored to its previous value after the block is executed.\n\nThe macro returns the value of the last expression in the block.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@with!","category":"page"},{"location":"#Kezdi.With.@with!","page":"Home","title":"Kezdi.With.@with!","text":"@with! df begin\n    # do something with df\nend\n\nThe @with! macro is a convenience macro that allows you to set the current data frame and perform operations on it in a single block. The first argument is the data frame to set as the current data frame, and the second argument is a block of code to execute. The data frame is set as the current data frame for the duration of the block, and then restored to its previous value after the block is executed.\n\nThe macro does not have a return value, it overwrites the data frame directly.\n\n\n\n\n\n","category":"macro"},{"location":"#Differences-to-standard-Julia-and-DataFrames-syntax","page":"Home","title":"Differences to standard Julia and DataFrames syntax","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To maximize convenience for Stata users, Kezdi.jl has a number of differences to standard Julia and DataFrames syntax.","category":"page"},{"location":"#Everything-is-a-macro","page":"Home","title":"Everything is a macro","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"While there are a few convenience functions, most Kezdi.jl commands are macros that begin with @.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@tabulate Gear","category":"page"},{"location":"#Comma-is-used-for-options","page":"Home","title":"Comma is used for options","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Due to this non-standard syntax, Kezdi.jl uses the comma to separate options.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@regress log(MPG) log(Horsepower), robust","category":"page"},{"location":"","page":"Home","title":"Home","text":"Here log(MPG) and log(Horsepower) are the dependent and independent variables, respectively, and robust is an option. Options may also have arguments, like","category":"page"},{"location":"","page":"Home","title":"Home","text":"@regress log(MPG) log(Horsepower), cluster(Cylinders)","category":"page"},{"location":"#Automatic-variable-name-substitution","page":"Home","title":"Automatic variable name substitution","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Column names of the data frame can be used directly in the commands without the need to prefix them with the data frame name or using a Symbol.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@generate logHP = log(Horsepower)","category":"page"},{"location":"","page":"Home","title":"Home","text":"warning: No symbols or special strings\nOther data manipulation packages in Julia require column names to be passed as symbols or strings. Kezdi.jl does not require this, and it will not work if you try to use symbols or strings.","category":"page"},{"location":"","page":"Home","title":"Home","text":"danger: Reserved words cannot be used as variable names\nJulia reserved words, like begin, export, function and standard types like String, Int, Float64, etc., cannot be used as variable names in Kezdi.jl. If you have a column with a reserved word, rename it before passing it to Kezdi.jl.","category":"page"},{"location":"#Automatic-vectorization","page":"Home","title":"Automatic vectorization","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"All functions are automatically vectorized, so there is no need to use the . operator to broadcast functions over elements of a column. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"@generate logHP = log(Horsepower)","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you want to turn off automatic vectorization, use the convenience function DNV (\"do not vectorize\").","category":"page"},{"location":"","page":"Home","title":"Home","text":"@generate logHP = DNV(log(Horsepower))","category":"page"},{"location":"","page":"Home","title":"Home","text":"The exception is when the function operates on Vectors, in which case Kezdi.jl understands you want to apply the function to the entire column.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@collapse mean_HP = mean(Horsepower), by(Cylinders)","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you need to apply a function to individual elements of a column, you need to vectorize it with adding . after the function name:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@generate words = split(Model, \" \")\n@generate n_words = length.(words)","category":"page"},{"location":"","page":"Home","title":"Home","text":"tip: Note: `length(words)` vs `length.(words)`\nHere, words becomes a vector of vectors, where each element is a vector of words in the corresponding Model string. The function legth. will operate on each cell in words, counting the number of words in each Model string. By contrast, length(words) would return the number of elements in the words vector, which is the number of rows in the DataFrame.","category":"page"},{"location":"#The-@if-condition","page":"Home","title":"The @if condition","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Almost every command can be followed by an @if condition that filters the data frame. The command will only be executed on the subset of rows for which the condition evaluates to true. The condition can use any combination of column names and functions.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@summarize MPG @if Horsepower > median(Horsepower)","category":"page"},{"location":"","page":"Home","title":"Home","text":"tip: Note: vector functions in `@if` conditions\nAutovectorization rules also apply to @if conditions. If you use a vector function, it will be evaluated on the entire column, before subseting the data frame. By contrast, vector functions in @generate or @collapse commands are evaluated on the subset of rows that satisfy the condition.@generate HP_p75 = median(Horsepower) @if Horsepower > median(Horsepower)This code computes the median of horsepower values above the median, that is, the 75th percentile of the horsepower distribution. Of course, you can more easily do this calculation with @summarize:s = @summarize Horsepower\ns.p75","category":"page"},{"location":"#Handling-missing-values","page":"Home","title":"Handling missing values","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Kezdi.jl ignores missing values when aggregating over entire columns. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"@with DataFrame(A = [1, 2, missing, 4]) begin\n    @collapse mean_A = mean(A)\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"returns mean_A = 2.33.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Other functions typically return missing if any of the values are missing. If a function does not accept missing values, Kezdi.jl will pass it through passmissing to handle missing values.","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can also manually check for missing values with the ismissing function.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@with DataFrame(x = [1, 2, missing, 4]) begin\n    @generate y = log(x)\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"returns ","category":"page"},{"location":"","page":"Home","title":"Home","text":"4×2 DataFrame\n Row │ x        y\n     │ Int64?   Float64?\n─────┼─────────────────────────\n   1 │       1        0.0\n   2 │       2        0.693147\n   3 │ missing  missing\n   4 │       4        1.38629","category":"page"},{"location":"","page":"Home","title":"Home","text":"The same will hold for Dates.year, even though this function does not accept missing values.","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> @with DataFrame(x = [1, 2, missing, 4]) begin\n           @generate y = Dates.year(x)\n       end\n4×2 DataFrame\n Row │ x        y\n     │ Int64?   Int64?\n─────┼──────────────────\n   1 │       1        1\n   2 │       2        1\n   3 │ missing  missing\n   4 │       4        1","category":"page"},{"location":"","page":"Home","title":"Home","text":"warning: In `@if` conditions, `missing` is treated as `false`\nIn @if conditions, missing is treated as false. This is expected behavior from users, because when they test for a condition, they expect it to be true, not missing.@with DataFrame(x = [1, 2, missing, 4]) begin\n    @keep @if x <= 2\nendreturns [1, 2].","category":"page"},{"location":"#Row-count-variables","page":"Home","title":"Row-count variables","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The variable _n refers to the row number in the data frame, _N denotes the total number of rows. These can be used in @if conditions, as well.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@with DataFrame(A = [1, 2, 3, 4]) begin\n    @keep @if _n < 3\nend","category":"page"},{"location":"#Differences-to-Stata-syntax","page":"Home","title":"Differences to Stata syntax","text":"","category":"section"},{"location":"#All-commands-begin-with-@","page":"Home","title":"All commands begin with @","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To allow for Stata-like syntax, all commands begin with @. These are macros that rewrite your Kezdi.jl code to DataFrames.jl commands.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@tabulate Gear\n@keep @if Gear == 4\n@keep Model MPG Horsepower Weight Displacement Cylinders","category":"page"},{"location":"#@if-condition-also-begins-with-@","page":"Home","title":"@if condition also begins with @","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The @if condition is non-standard behavior in Julia, so it is also implemented as a macro.","category":"page"},{"location":"#@collapse-has-same-syntax-as-@egen","page":"Home","title":"@collapse has same syntax as @egen","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Unlike Stata, where egen and collapse have different syntax, Kezdi.jl uses the same syntax for both commands.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@egen mean_HP = mean(Horsepower), by(Cylinders)\n@collapse mean_HP = mean(Horsepower), by(Cylinders)","category":"page"},{"location":"#Different-function-names","page":"Home","title":"Different function names","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To maintain compatibility with Julia, we had to rename some functions. For example, count is called rowcount, missing is called ismissing in Kezdi.jl.","category":"page"},{"location":"#Missing-values","page":"Home","title":"Missing values","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"In Julia, the result of any operation involving a missing value is missing. The only exception is the ismissing function, which returns true if the value is missing and false otherwise. You cannot check for missing values with == missing.","category":"page"},{"location":"","page":"Home","title":"Home","text":"For convenience, Kezdi.jl has special rules about Handling missing values. We also extended the ismissing function to work with multiple arguments.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@with DataFrame(x = [1, 2, missing, 4], y = [1, missing, 3, 4]) begin\n    @generate z = ismissing(x, y)\nend\n4×3 DataFrame\n Row │ x        y        z\n     │ Int64?   Int64?   Bool\n─────┼─────────────────────────\n   1 │       1        1  false\n   2 │       2  missing   true\n   3 │ missing        3   true\n   4 │       4        4  false","category":"page"},{"location":"","page":"Home","title":"Home","text":"Missing is not greater than anything, so comparison with missing values will always return missing. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"warning: In `@if` conditions, `missing` is treated as `false`\nIn @if conditions, missing is treated as false. This is expected behavior from users, because when they test for a condition, they expect it to be true, not missing.@with DataFrame(x = [1, 2, missing, 4]) begin\n    @keep @if x <= 2\nendreturns [1, 2].","category":"page"},{"location":"#Convenience-functions","page":"Home","title":"Convenience functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"distinct","category":"page"},{"location":"#Kezdi.distinct","page":"Home","title":"Kezdi.distinct","text":"distinct(x::AbstractVector) = unique(x)\n\nConvenience function to get the distinct values of a vector.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"rowcount","category":"page"},{"location":"#Kezdi.rowcount","page":"Home","title":"Kezdi.rowcount","text":"rowcount(x::AbstractVector) = length(keep_only_values(x))\n\nCount the number of valid values in a vector.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"DNV","category":"page"},{"location":"#Kezdi.DNV","page":"Home","title":"Kezdi.DNV","text":"DNV(f(x))\n\nIndicate that the function f should not be vectorized. The name DNV is only used for parsing, do not call it directly.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"keep_only_values","category":"page"},{"location":"#Kezdi.keep_only_values","page":"Home","title":"Kezdi.keep_only_values","text":"keep_only_values(x::AbstractVector) -> AbstractVector\n\nReturn a vector with only the values of x, excluding any missingvalues,nothings,Infa andNaN`s.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"ismissing","category":"page"},{"location":"#Base.ismissing","page":"Home","title":"Base.ismissing","text":"ismissing(args...) -> Bool\n\nReturn true if any of the arguments is missing.\n\n\n\n\n\n","category":"function"},{"location":"#Acknowledgements","page":"Home","title":"Acknowledgements","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"[stata]: Stata is a registered trademark of StataCorp LLC. Kezdi.jl is not affiliated with StataCorp LLC.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Inspiration for the package came from Tidier.jl, a similar package launched by Karandeep Singh that provides a dplyr-like interface for Julia. Johannes Boehm has also developed a similar package, Douglass.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The package is built on top of DataFrames.jl, FreqTables.jl and FixedEffectModels.jl. The @with function relies on Chain.jl by Julius Krumbiegel.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The package is named after Gabor Kezdi, a Hungarian economist who has made significant contributions to teaching data analysis.","category":"page"}]
}
