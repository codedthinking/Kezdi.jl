global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro mockmacro(exprs...)
    command = :mockmacro
    transpile(exprs, command)
end

macro replace(exprs...)
    command = :replace
    cmd = transpile(exprs, command)
    rewrite(cmd) 
end

macro generate(exprs...)
    command = :generate
    cmd = transpile(exprs, command)
    rewrite(cmd)
end

macro egen(exprs...)
    command = :egen
    cmd = transpile(exprs, command)
    rewrite(cmd)
end

macro collapse(exprs...)
    command = :collapse
    cmd = transpile(exprs, command)
    rewrite(cmd)
end

macro keep(exprs...)
    command = :keep
    cmd = transpile(exprs, command)
    rewrite(cmd)
end

macro drop(exprs...)
    command = :drop
    cmd = transpile(exprs, command)
    rewrite(cmd)
end
