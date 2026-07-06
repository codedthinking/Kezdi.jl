using PrecompileTools

@setup_workload begin
    _df = DataFrame(x = [1.0, 2.0, missing], s = ["a", "b", "c"], g = [1, 1, 2])
    # an @if condition reaches a command macro as a :macrocall expression
    _if = cond -> Expr(:macrocall, Symbol("@if"), LineNumberNode(0), cond)
    @compile_workload begin
        # expansion pipeline: one representative parse+rewrite per command
        rewrite(parse_command((:(y = x + 1),), :generate))
        rewrite(parse_command((:(y = x + 1), _if(:(x > 2))), :generate))
        rewrite(parse_command((:(x = 2 * x),), :replace))
        rewrite(parse_command((:x, _if(:(x < 2))), :keep))
        rewrite(parse_command((:s,), :drop))
        rewrite(parse_command((:(m = (mean(x), by(g))),), :collapse))
        rewrite(parse_command((:(m = (sum(x), by(g))),), :egen))
        rewrite(parse_command((:x,), :sort))
        rewrite(parse_command((:x,), :order))
        rewrite(parse_command((:x, :g), :tabulate))
        rewrite(parse_command((:x,), :summarize))
        rewrite(parse_command((:x, :g), :regress))
        rewrite(parse_command((), :count))
        rewrite(parse_command((:x,), :list))
        rewrite(parse_command((), :describe))
        rewrite(parse_command((:x, :s), :mvencode))
        # runtime helpers
        setdf(_df)
        apply_function(log, [1.0, missing])
        apply_function(mean, [1.0, missing, 3.0])
        summarize(getdf(), :x)
        _describe(getdf())
        setdf(nothing)
    end
end
