# use multiple dispatch to generate code 
generate(command::Command) = generate(Val(command.command), command)

function generate(::Val{:keep}, command::Command)
    return :(select($(command.arguments...)))
end

function generate(::Val{:generate}, command::Command)
end

function build_assignment_formula(expr::Expr)
    expr.head == :(=) || error("Expected assignment expression")
    no_variable = false
    vars = extract_variable_references(expr)
    LHS = [y[2] for y in vars if y[1] == :LHS][1]
    RHS = [y[2] for y in vars if y[1] == :RHS]
    if length(RHS) == 0
        # if no variable is used in RHS of assignment, create an anonymous variable
        RHS = [:_]
        no_variable = true
    end
    columns_to_transform = Expr(:vect, [QuoteNode(x) for x in RHS]...)
    arguments = Expr(:tuple, RHS...)
    target_column = QuoteNode(LHS)
    assignment_expression = Expr(Symbol("->"), 
        arguments, 
        Expr(:block,
            Expr(:call, Symbol("=>"), 
                expr.args[2],
                target_column
                )
            )
        )
    return no_variable ? assignment_expression : Expr(:call, Symbol("=>"), 
        columns_to_transform,
        assignment_expression
        )
end

function extract_variable_references(expr::Any, left_of_assignment::Bool=false)
    if expr isa Symbol
        return left_of_assignment ? [(:LHS, expr)] : [(:RHS, expr)]
    elseif expr isa Expr
        if expr.head == :call
            return vcat(extract_variable_references.(expr.args[2:end], left_of_assignment)...)
        elseif expr.head == Symbol("=")
            return vcat(extract_variable_references.(expr.args[1:1], true)..., extract_variable_references.(expr.args[2:end], false)...)
        else
            return vcat(extract_variable_references.(expr.args, left_of_assignment)...)
        end
    else
        return []
    end
end

function replace_variable_references(expr::Any)
    if expr isa Symbol
        return QuoteNode(expr)
    elseif expr isa Expr
        if expr.head == :call
            return Expr(:call, expr.args[1], replace_variable_references.(expr.args[2:end])...)
        else
            return Expr(expr.head, replace_variable_references.(expr.args)...)
        end
    else
        return expr
    end
end

