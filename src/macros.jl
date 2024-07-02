global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro mockmacro(exprs...)
    command = :mockmacro
    parse(exprs, command)
end

"""
    @keep df y1 y2 ... [@if condition]

Keep only the variables `y1`, `y2`, etc. in `df`. If `condition` is provided, only the rows for which the condition is true are kept.  
"""
macro keep(exprs...)
    :keep |> parse(exprs) |> rewrite
end

"""
    @drop df y1 y2 ... 
or
    @drop df [@if condition]    

Drop the variables `y1`, `y2`, etc. from `df`. If `condition` is provided, the rows for which the condition is true are dropped.
"""
macro drop(exprs...)
    :drop |> parse(exprs) |> rewrite
end

"""
    @generate df y = expr [@if condition]

Create a new variable `y` in `df` by evaluating `expr`. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. 
"""
macro generate(exprs...)
    :generate |> parse(exprs) |> rewrite
end

"""
    @replace df y = expr [@if condition]

Replace the values of `y` in `df` with the result of evaluating `expr`. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.
"""
macro replace(exprs...)
    :replace |> parse(exprs) |> rewrite
end

"""
    @egen df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]

Generate new variables in `df` by evaluating expressions `expr1`, `expr2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If `by` is provided, the operation is executed by group.
"""
macro egen(exprs...)
    :egen |> parse(exprs) |> rewrite
end

"""
    @collapse df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]

Collapse `df` by evaluating expressions `expr1`, `expr2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. If `by` is provided, the operation is executed by group.
"""
macro collapse(exprs...)
    :collapse |> parse(exprs) |> rewrite
end

"""
    @summarize df y [@if condition]

Summarize the variable `y` in `df`. If `condition` is provided, the operation is executed only on rows for which the condition is true.
"""
macro summarize(exprs...)
    :summarize |> parse(exprs) |> rewrite
end

"""
    @regress df y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]

Estimate a regression model in `df` with dependent variable `y` and independent variables `x1`, `x2`, etc. If `condition` is provided, the operation is executed only on rows for which the condition is true. If `robust` is provided, robust standard errors are calculated. If `cluster` is provided, clustered standard errors are calculated.
"""
macro regress(exprs...)
    :regress |> parse(exprs) |> rewrite
end

"""
    @tabulate df y1 y2 ... [@if condition]

Create a frequency table for the variables `y1`, `y2`, etc. in `df`. If `condition` is provided, the operation is executed only on rows for which the condition is true.
"""
macro tabulate(exprs...)
    :tabulate |> parse(exprs) |> rewrite
end

"""
    @count df [@if condition]

Count the number of rows for which the condition is true. If `condition` is not provided, the total number of rows is counted.
"""
macro count(exprs...)
    :count |> parse(exprs) |> rewrite
end

macro sort(exprs...)
    :sort |> parse(exprs) |> rewrite
end

macro order(exprs...)
    :order |> parse(exprs) |> rewrite
end

macro use(fname)
    :(use($fname)) |> esc
end

macro list()
    :(getdf()) |> esc
end

macro head(n=5)
    :(first(getdf(), $n)) |> esc
end

macro tail(n=5)
    :(last(getdf(), $n)) |> esc
end

macro names()
    :(names(getdf())) |> esc
end