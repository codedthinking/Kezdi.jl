using DataFrames
aside_commands = (Symbol("@regress"), Symbol("@test"), Symbol("@summarize"))
operations = (:+, :-, :*, :/, :^, :%, :&, :|, :<, :<=, :(==), :>, :>=, :!=)
scalars = ()
global_logger(Logging.ConsoleLogger(stderr, Logging.Info))

macro replace(exprs...)
    command = Symbol("@replace")
    cmd = transpile(exprs, command)
    return cmd 
end

macro generate(exprs...)
    command = Symbol("@generate")
    cmd = transpile(exprs, command)
    rewrite(cmd)
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

function rewrite(command::Command)::Expr
    cmd = command.command
    first_arg = command.arguments[1]
    
    if !(cmd in aside_commands)
        # change the values in the dataframe 
        if isa(first_arg, Expr) && first_arg.head != Symbol("=")
            error("The arguments for the datawrangling commands must have an assignment expression!")
        end
    end

    if cmd  == Symbol("@replace")
        return replace(command)
    end
    if cmd == Symbol("@generate")
        return generate(command)
    end
    if cmd == Symbol("@egen")
        return generate(command)
    end
    if cmd == Symbol("@collapse")
        return collapse(command)
    end
    if cmd == Symbol("@summarize")
        return summarize(command)
    end
    if cmd == Symbol("@regress")
        return regress(command)
    end
end

function generate(cmd::Command)::Expr
    df = cmd.df
    condition = process_expression(cmd.condition, df)
    new_col = cmd.arguments[1].args[1]
    @info "arguments are $(cmd.arguments[1])"
    result = process_expression(cmd.arguments[1], df)
    options = cmd.options
    if !isnothing(condition)
        result.args[1] = :($df[$condition, $(Meta.quot(new_col))])
    end
    @info "using $result to generate new col"
    :($(esc(result)))
end

process_expression(e, _) = e

function process_expression(e::Expr, df::Symbol)::Expr
    args = []
    for arg in e.args
        if isa(arg, Expr)
            arg = process_expression(arg, df)
            if arg.head == :call && length(arg.args) == 2
                arg = :(broadcast(eval($(arg.args[1])),eval($(arg.args[2]))))
            end
        end

        if !isa(arg, Symbol)
            push!(args, arg)
            continue
        end


        if !in(arg,scalars) && !in(arg, operations)
            arg = :($df.$arg)
        elseif in(arg, scalars)
            arg = Symbol("$arg")
        elseif in(arg, operations)
            arg = Symbol(".$arg")
        end
        push!(args, arg)
    end
    return Expr(e.head, args...)
end