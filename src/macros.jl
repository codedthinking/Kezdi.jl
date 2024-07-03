global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

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
    @drop if condition]    

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
    @count if condition]

Count the number of rows for which the condition is true. If `condition` is not provided, the total number of rows is counted.
"""
macro count(exprs...)
    :count |> parse(exprs) |> rewrite
end

"""
    @sort y1 y2 ...[, desc]

Sort the data frame by the variables `y1`, `y2`, etc. By default, the variables are sorted in ascending order. If `desc` is provided, the variables are sorted in descending order
"""
macro sort(exprs...)
    :sort |> parse(exprs) |> rewrite
end

"""
    @order y1 y2 ... [desc] [last] [after=var] [before=var] [alphabetical]

Reorder the variables `y1`, `y2`, etc. in the data frame. By default, the variables are ordered in the order they are listed. If `desc` is provided, the variables are ordered in descending order. If `last` is provided, the variables are moved to the end of the data frame. If `after` is provided, the variables are moved after the variable `var`. If `before` is provided, the variables are moved before the variable `var`. If `alphabetical` is provided, the variables are ordered alphabetically.
"""
macro order(exprs...)
    :order |> parse(exprs) |> rewrite
end

"""
    @use "filename.dta"

Read the data from the file `filename.dta` and set it as the global data frame.
"""
macro use(fname)
    :(use($fname)) |> esc
end

"""
    @list

Display the entire data frame.
"""
macro list()
    :(getdf() |> display_and_return) |> esc
end

"""
    @head [n]

Display the first `n` rows of the data frame. By default, `n` is 5.
"""
macro head(n=5)
    :(first(getdf(), $n) |> display_and_return) |> esc
end

"""
    @tail [n]

Display the last `n` rows of the data frame. By default, `n` is 5.
"""
macro tail(n=5)
    :(last(getdf(), $n) |> display_and_return) |> esc
end

"""
    @names

Display the names of the variables in the data frame.
"""
macro names()
    :(names(getdf()) |> display_and_return) |> esc
end

"""
    @rename oldname newname

Rename the variable `oldname` to `newname` in the data frame.
"""
macro rename(exprs...)
    :rename |> parse(exprs) |> rewrite
end
