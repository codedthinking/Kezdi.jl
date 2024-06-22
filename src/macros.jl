global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro mockmacro(exprs...)
    command = :mockmacro
    parse(exprs, command)
end

macro replace(exprs...)
    command = :replace
    cmd = parse(exprs, command)
    rewrite(cmd) 
end

macro generate(exprs...)
    command = :generate
    cmd = parse(exprs, command)
    rewrite(cmd)
end

macro egen(exprs...)
    command = :egen
    cmd = parse(exprs, command)
    rewrite(cmd)
end

macro collapse(exprs...)
    command = :collapse
    cmd = parse(exprs, command)
    rewrite(cmd)
end

macro keep(exprs...)
    command = :keep
    cmd = parse(exprs, command)
    rewrite(cmd)
end

macro drop(exprs...)
    command = :drop
    cmd = parse(exprs, command)
    rewrite(cmd)
end
