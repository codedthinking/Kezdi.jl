macro mockmacro(exprs...)
    command = :mockmacro
    parse(exprs, command)
end

"""
    @keep y1 y2 ... [@if condition]

Keep only the variables `y1`, `y2`, etc. in `df`. If `condition` is provided, only the rows for which the condition is true are kept.  
"""
macro keep(exprs...)
    :keep |> parse(exprs) |> rewrite
end

"""
    @drop y1 y2 ... 
or
    @drop [@if condition]    

Drop the variables `y1`, `y2`, etc. from `df`. If `condition` is provided, the rows for which the condition is true are dropped.
"""
macro drop(exprs...)
    :drop |> parse(exprs) |> rewrite
end

"""
    @generate y = expr [@if condition]

Create a new variable `y` in `df` by evaluating `expr`. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. 
"""
macro generate(exprs...)
    :generate |> parse(exprs) |> rewrite
end

"""
    @replace y = expr [@if condition]

Replace the values of `y` in `df` with the result of evaluating `expr`. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.
"""
macro replace(exprs...)
    :replace |> parse(exprs) |> rewrite
end

"""
    @egen y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]

Generate new variables in `df` by evaluating expressions `expr1`, `expr2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If `by` is provided, the operation is executed by group.
"""
macro egen(exprs...)
    :egen |> parse(exprs) |> rewrite
end

"""
    @collapse y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]

Collapse `df` by evaluating expressions `expr1`, `expr2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. If `by` is provided, the operation is executed by group.
"""
macro collapse(exprs...)
    :collapse |> parse(exprs) |> rewrite
end

"""
    @summarize y [@if condition]

Summarize the variable `y` in `df`. If `condition` is provided, the operation is executed only on rows for which the condition is true.
"""
macro summarize(exprs...)
    :summarize |> parse(exprs) |> rewrite
end

"""
    @regress y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]

Estimate a regression model in `df` with dependent variable `y` and independent variables `x1`, `x2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. If `robust` is provided, robust standard errors are calculated. If `cluster` is provided, clustered standard errors are calculated.

The regression is limited to rows for which all variables are values. Missing values, infinity, and NaN are automatically excluded.
"""
macro regress(exprs...)
    :regress |> parse(exprs) |> rewrite
end

"""
    @tabulate y1 y2 ... [@if condition]

Create a frequency table for the variables `y1`, `y2`, etc. in `df`. If `condition` is provided, the operation is executed only on rows for which the condition is true.
"""
macro tabulate(exprs...)
    :tabulate |> parse(exprs) |> rewrite
end

"""
    @count [@if condition]

Count the number of rows for which the condition is true. If `condition` is not provided, the total number of rows is counted.
"""
macro count(exprs...)
    :count |> parse(exprs) |> rewrite
end

"""
    @sort y1 y2 ... , [desc]

Sort the data frame by the variables `y1`, `y2`, etc. By default, the variables are sorted in ascending order. If `desc` is provided, the variables are sorted in descending order
"""
macro sort(exprs...)
    :sort |> parse(exprs) |> rewrite
end

"""
    @order y1 y2 ... , [desc] [last] [after=var] [before=var] [alphabetical]

Reorder the variables `y1`, `y2`, etc. in the data frame. By default, the variables are ordered in the order they are listed. If `desc` is provided, the variables are ordered in descending order. If `last` is provided, the variables are moved to the end of the data frame. If `after` is provided, the variables are moved after the variable `var`. If `before` is provided, the variables are moved before the variable `var`. If `alphabetical` is provided, the variables are ordered alphabetically.
"""
macro order(exprs...)
    :order |> parse(exprs) |> rewrite
end

"""
    @list [y1 y2...] [@if condition]

Display the entire data frame or the rows for which the condition is true. If variable names are provided, only the variables in the list are displayed.
"""
macro list(exprs...)
    :list |> parse(exprs) |> rewrite
end


"""
    @use "filename.dta", [clear]

Read the data from the file `filename.dta` and set it as the global data frame. If there is already a global data frame, `@use` will throw an error unless the `clear` option is provided
"""
macro use(exprs...)
    command = parse(exprs, :use)
    length(command.arguments) == 1 || ArgumentError("@use takes a single file name as an argument:\n@use \"filename.dta\"[, clear]") |> throw
    # clear is the only permissible option
    isempty(filter(x -> x != :clear, command.options)) || ArgumentError("Invalid options $(string.(command.options)). Correct syntax:\n@use \"filename.dta\"[, clear]") |> throw
    fname = command.arguments[1]
    clear = :clear in command.options
    isnothing(getdf()) || clear || ArgumentError("There is already a global data frame set. If you want to replace it, use the \", clear\" option.") |> throw

    :(println("$(Kezdi.prompt())$($command)\n"); Kezdi.use($fname)) |> esc
end

"""
    @save "filename.dta", [replace]

Save the global data frame to the file `filename.dta`. If the file already exists, the `replace` option must be provided.
"""
macro save(exprs...)
    command = parse(exprs, :save)
    length(command.arguments) == 1 || ArgumentError("@save takes a single file name as an argument:\n@save \"filename.dta\"") |> throw
    isnothing(getdf()) && ArgumentError("There is no data frame to save.") |> throw
    fname = command.arguments[1]
    replace = :replace in command.options
    ispath(fname) && !replace && ArgumentError("File $fname already exists.") |> throw
    :(println("$(Kezdi.prompt())$($command)\n"); Kezdi.save($fname)) |> esc
end

"""
    @append "filename.dta"

Append the data from the file `filename.dta` to the global data frame. Columns that are not common filled with missing values.
"""
macro append(exprs...)
    command = parse(exprs, :append)
    length(command.arguments) == 1 || ArgumentError("@append takes a single file name as an argument:\n@append \"filename.dta\"") |> throw
    isnothing(getdf()) && ArgumentError("There is no data frame to append to.") |> throw
    fname = command.arguments[1]
    :(println("$(Kezdi.prompt())$($command)\n"); Kezdi.append($fname)) |> esc
end
"""
    @head [n]

Display the first `n` rows of the data frame. By default, `n` is 5.
"""
macro head(n=5)
    :(println("$(Kezdi.prompt())@head $($n)\n"); first(getdf(), $n) |> display_and_return) |> esc
end

"""
    @tail [n]

Display the last `n` rows of the data frame. By default, `n` is 5.
"""
macro tail(n=5)
    :(println("$(Kezdi.prompt())@tail $($n)\n"); last(getdf(), $n) |> display_and_return) |> esc
end

"""
    @names

Display the names of the variables in the data frame.
"""
macro names()
    :(println("$(Kezdi.prompt())@names\n"); names(getdf()) |> display_and_return) |> esc
end

"""
    @rename oldname newname

Rename the variable `oldname` to `newname` in the data frame.
"""
macro rename(exprs...)
    :rename |> parse(exprs) |> rewrite
end

"""
    @clear

Clears the global dataframe.
"""
macro clear()
    :(println("$(Kezdi.prompt())@clear\n"); setdf(nothing))
end

"""
    @describe [y1] [y2]...

Show the names and data types of columns of the data frame. If no variable names given, all are shown. 
"""
macro describe(exprs...)
    :describe |> parse(exprs) |> rewrite
end

"""
    @reshape long y1 y2 ... i(varlist) j(var) 
    @reshape wide y1 y2 ... i(varlist) j(var)

Reshape the data frame from wide to long or from long to wide format. The variables `y1`, `y2`, etc. are the variables to be reshaped. The `i(var)` and `j(var)` are the variables that define the row and column indices in the reshaped data frame.

The option `i()` may include multiple variables, like `i(var1, var2, var3)`. The option `j()` must include only one variable.
"""
macro reshape(exprs...)
    if exprs[1] == :long
        return quote
            :reshape_long |> parse(exprs[2:end]) |> rewrite
        end
    elseif exprs[1] == :wide
        :reshape_wide |> parse(exprs[2:end]) |> rewrite
    else
        return quote
            ArgumentError("Invalid option $(exprs[1]). Correct syntax:\n@reshape long y1 y2 ... i(var) j(var)\n@reshape wide y1 y2 ... i(var) j(var)") |> throw
        end
    end
end

"""
    @mvencode y1 y2 [_all] ... [if condition], [mv(value)]

Encode missing values in the variables `y1`, `y2`, etc. in the data frame. If `condition` is provided, the operation is executed only on rows for which the condition is true. If `mv` is provided, the missing values are encoded with the value `value`. By default value is `missing` making no changes on the dataframe. Using `_all` encodes all variables of the DataFrame.
"""
macro mvencode(exprs...)
    :mvencode |> parse(exprs) |> rewrite
end
