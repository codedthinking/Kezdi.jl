# use multiple dispatch to generate code 
generate(command::Command) = generate(Val(command.command), command)

function generate(::Value{:keep}, command::Command)::Vector{Expr}
    return [:(select($(command.arguments...)))]
end