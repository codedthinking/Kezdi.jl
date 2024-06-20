global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro mockmacro(exprs...)
    command = Symbol("@mockmacro")
    transpile(exprs, command)
end


macro replace(exprs...)
    command = Symbol("@replace")
    cmd = transpile(exprs, command)
    rewrite(cmd) 
end

macro generate(exprs...)
    command = Symbol("@generate")
    cmd = transpile(exprs, command)
    rewrite(cmd)
end

