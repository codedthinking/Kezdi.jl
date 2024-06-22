global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro mockmacro(exprs...)
    command = :mockmacro
    parse(exprs, command)
end

macro replace(exprs...)
    :replace |> parse(exprs) |> rewrite
end

macro generate(exprs...)
    :generate |> parse(exprs) |> rewrite
end

macro egen(exprs...)
    :egen |> parse(exprs) |> rewrite
end

macro collapse(exprs...)
    :collapse |> parse(exprs) |> rewrite
end

macro keep(exprs...)
    :keep |> parse(exprs) |> rewrite
end

macro drop(exprs...)
    :drop |> parse(exprs) |> rewrite
end