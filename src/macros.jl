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

macro summarize(exprs...)
    command = Symbol("@summarize")
    cmd = transpile(exprs, command)
    return cmd
end

macro collapse(exprs...)
    command = Symbol("@collapse")
    cmd = transpile(exprs, command)
    return cmd 
end

macro with(exprs...)
    df = exprs[1]
    globals = Tuple(arg for arg in exprs[2].args if arg!=:globals)
    exs = []
    for expr in exprs[3:end]
        if !isa(expr, Expr)
            push!(exs, expr)
            continue
        end
        if expr.head != :block && expr.head != :macrocall
            push!(exs, expr)
            continue
        end
        if expr.head == :macrocall
            push!(exs, eval(expr))
        end
        block = [arg for arg in expr.args if !isa(arg, LineNumberNode)]
        block = [arg.head == :macrocall ? eval(arg) : arg for arg in block]
        push!(exs, block)
    end
    return df, globals, exs
end