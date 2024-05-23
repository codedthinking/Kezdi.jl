macro replace(exprs...)
    command = Symbol("@replace")
    cmd = transpile(exprs, command)
    return cmd 
end

macro generate(exprs...)
    command = Symbol("@generate")
    cmd = transpile(exprs, command)
    return cmd 
end

macro egen(exprs...)
    command = Symbol("@egen")
    cmd = transpile(exprs, command)
    return cmd 
end

macro regress(exprs...)
    command = Symbol("@regress")
    cmd = transpile(exprs, command)
    return cmd 
end

macro test(exprs...)
    command = Symbol("@test")
    cmd = transpile(exprs, command)
    return cmd 
end

macro collapse(exprs...)
    command = Symbol("@collapse")
    cmd = transpile(exprs, command)
    return cmd 
end