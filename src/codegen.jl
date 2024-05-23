# use multiple dispatch to generate code 
generate(command::Command) = generate(Val(command.command), command)

function generate(::Val{:keep}, command::Command)::Vector{Expr}
    return [:(select($(command.arguments...)))]
end

function generate(::Val{:replace}, command::Command)::Vector{Expr}
    return [:(transform($(command.arguments...)))]
end