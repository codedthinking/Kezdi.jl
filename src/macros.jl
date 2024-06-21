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
