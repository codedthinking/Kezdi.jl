# Kezdi.jl refactoring plan

This is a step-by-step implementation plan. It modernizes Kezdi.jl for the current Julia
compiler landscape (1.10 LTS, 1.12.x stable): it removes `eval`/reflection at
macro-expansion time, removes type piracy, makes `@with` exception-safe, moves
runtime checks out of macro expansion, cleans up dependencies, and adds a
precompilation workload.

## Ground rules for the implementer

1. **Work phase by phase, in order.** Each phase is independently shippable. Make one
   commit per phase with the suggested commit message.
2. **Run the full test suite after every phase**:
   ```sh
   julia --project=. -e 'using Pkg; Pkg.test()'
   ```
   A phase is done only when tests pass. Do not start the next phase on a red suite.
3. **The user-facing macro syntax must not change.** `@generate y = x + 1 @if x > 2`
   must keep working exactly as documented in `docs/` and `README.md`.
4. **Behavior parity is the acceptance bar.** Unless a step explicitly says "behavior
   change", the observable results of every command on the same data must be identical
   before and after.
5. Do not refactor anything not listed here. Note ideas in the PR description instead.
6. When a step says "delete", delete — do not comment out.

---

## Phase 0 — Baseline

**Goal:** know the starting state.

1. Run `julia --project=. -e 'using Pkg; Pkg.test()'` on Julia 1.10 (or the newest
   available). Record the result. All subsequent phases compare against this.
2. Record load time: `julia --project=. -e '@time using Kezdi'` (run twice, report the
   second run). This is compared again in Phase 6.

No commit.

---

## Phase 1 — Compat bounds and CI matrix

**Goal:** drop EOL Julia 1.9, test on 1.12.

**Files:** `Project.toml`, `.github/workflows/CI.yml`, `README.md`, `docs/`

1. In `Project.toml`, change:
   ```toml
   julia = "1.9, 1.10, 1.11"
   ```
   to
   ```toml
   julia = "1.10"
   ```
   (Caret semantics: this allows every 1.x ≥ 1.10, including 1.11 and 1.12.)
2. In `.github/workflows/CI.yml`, change the version matrix from `'1.11' / '1.10' / '1.9'`
   to `'1.10'`, `'1.11'`, `'1.12'`. Optionally add `'pre'` as a fourth entry together with
   an `allow_failure`-style setup (`continue-on-error: true` keyed on the version) — skip
   this if it complicates the matrix.
3. `grep -rn "1\.9" README.md docs/ --include="*.md"` and update any prose that claims
   1.9 support.

**Acceptance:** `Pkg.test()` green locally; CI YAML parses (`python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/CI.yml'))"`).

**Commit:** `Drop Julia 1.9 (EOL), test on 1.10 LTS through 1.12`

---

## Phase 2 — Dependency cleanup (test/docs-only packages out of [deps])

**Goal:** users installing Kezdi should not download Expronicon (deprecated upstream),
BenchmarkTools, or RDatasets.

**Files:** `Project.toml`, `test/runtests.jl`, `test/speed.jl`, `docs/Project.toml`

1. **Replace Expronicon's `@test_expr`.** It is used only in `test/codegen.jl`. Add to
   `test/runtests.jl` (below the existing `@return_arguments` helpers), and delete
   `using Expronicon`:
   ```julia
   normalize_expr(x) = x
   normalize_expr(ex::Expr) = Base.remove_linenums!(deepcopy(ex))

   # drop-in replacement for Expronicon.@test_expr: compare Exprs ignoring line numbers
   macro test_expr(ex)
       Meta.isexpr(ex, :call, 3) && ex.args[1] == :(==) ||
           error("@test_expr expects `lhs == rhs`")
       :(@test normalize_expr($(esc(ex.args[2]))) == normalize_expr($(esc(ex.args[3]))))
   end
   ```
2. **Move the benchmark out of the test suite.** Create `benchmark/benchmarks.jl`
   containing the current contents of `test/speed.jl` plus `using BenchmarkTools, Kezdi`
   at the top. Delete `test/speed.jl`, delete the `@testset "Speed"` block from
   `test/runtests.jl`, and delete `using BenchmarkTools` from `test/runtests.jl`.
3. **`Project.toml`:** remove `Expronicon`, `BenchmarkTools`, and `RDatasets` from
   `[deps]` and `[compat]`. RDatasets and BenchmarkTools are already in
   `docs/Project.toml` for the docs build; verify (`grep -n "" docs/Project.toml`) and
   leave the docs project as-is. Leave `[extras]`/`[targets]` with `Test` only.
4. `grep -rn "Expronicon\|BenchmarkTools\|RDatasets" src/ test/ Project.toml` must come
   back empty (docs/ may still match).

**Acceptance:** `Pkg.test()` green. `julia --project=. -e 'using Kezdi'` works from a
fresh resolve (`rm Manifest.toml; Pkg.instantiate()` first).

**Commit:** `Remove test/docs-only packages from package dependencies`

---

## Phase 3 — Remove type piracy on Base.ismissing; add Aqua

**Goal:** stop redefining `Base.ismissing` for arbitrary varargs (an invalidation
source and a correctness hazard for every other package in the session).

**Files:** `src/functions.jl`, `src/codegen.jl`, `src/Kezdi.jl`, `test/`, `Project.toml`

1. In `src/functions.jl`, **delete** the pirated method and its docstring
   (currently lines 128–133):
   ```julia
   Base.ismissing(args...) = any(ismissing.(args))
   ```
   Replace with a Kezdi-owned function:
   ```julia
   """
       anymissing(args...)

   Return `true` if any of the arguments is `missing`. Multi-argument `ismissing(x, y)`
   inside Kezdi commands is rewritten to this function.
   """
   anymissing(args...) = any(ismissing, args)
   ```
2. Export `anymissing` from `src/Kezdi.jl` (add to the second `export` line).
3. **Rewrite multi-argument `ismissing` calls at expansion time.** In
   `src/codegen.jl`, at the very top of `vectorize_function_calls(expr::Expr)`
   (immediately after the `isfunctioncall(expr) || return ...` line), insert:
   ```julia
   # ismissing(x, y, ...) has no multi-arg method in Base; route to Kezdi.anymissing
   if expr.head == :call && expr.args[1] == :ismissing && length(expr.args) > 2
       expr = Expr(:call, :anymissing, expr.args[2:end]...)
   end
   ```
   Then make `anymissing` vectorize like `ismissing` does (i.e. broadcast **without**
   `passmissing`, otherwise `anymissing.(missing, 2)` would return `missing` instead of
   `true`). In `src/codegen.jl` change:
   ```julia
   operates_on_missing(expr::Any) = (expr isa Symbol && expr == :ismissing) || operates_on_type(expr, Missing)
   ```
   to
   ```julia
   operates_on_missing(expr::Any) = (expr isa Symbol && expr in (:ismissing, :anymissing)) || operates_on_type(expr, Missing)
   ```
4. In `src/Kezdi.jl`, delete the vestigial `import Base: count` (nothing defines a
   `Base.count` method; the `@count` macro does not need it).
5. **Add Aqua.** In `Project.toml` add `Aqua = "4c88cf16-eb10-579e-8560-4a9242c79595"`
   to `[extras]`, add `Aqua = "0.8"` to `[compat]`, and set
   `test = ["Test", "Aqua"]` in `[targets]`. Create `test/aqua.jl`:
   ```julia
   using Aqua
   Aqua.test_all(Kezdi; ambiguities=false, deps_compat=(check_extras=false,))
   ```
   and add to `test/runtests.jl`:
   ```julia
   @testset "Aqua" begin
       include("aqua.jl")
   end
   ```
   If `Aqua.test_all` reports issues other than what this plan already fixes, disable
   *only* the failing check with a keyword (as done for `ambiguities`) and leave a
   `# TODO` comment naming the failure — do not chase them in this phase.
6. Add a regression test in `test/commands.jl` near the existing `ismissing` tests
   (around line 134):
   ```julia
   @testset "multi-argument ismissing" begin
       df = DataFrame(x = [1, missing, 3], y = [missing, missing, 30])
       df2 = @with df @generate z = ismissing(x, y)
       @test df2.z == [true, true, false]
   end
   ```

**Behavior change (document in PR):** `Base.ismissing(a, b)` no longer works *outside*
Kezdi commands. Inside commands, `ismissing(x, y)` keeps working via the rewrite.

**Acceptance:** `Pkg.test()` green including Aqua's piracy check.

**Commit:** `Remove type piracy on Base.ismissing; rewrite to Kezdi.anymissing; add Aqua`

---

## Phase 4 — Exception safety and expansion-time side effects

**Goal:** `@with` must restore the previous global DataFrame even when the block
throws; `@use`/`@save`/`@append` must perform their runtime checks at run time, not at
macro-expansion time; loading Kezdi must not touch the global logger.

**Files:** `src/With.jl`, `src/macros.jl`, `src/parse.jl`, `src/Kezdi.jl`, `Project.toml`, tests

### 4a. `@with` via try/finally

Replace the whole `rewrite_with_block` function in `src/With.jl` with:

```julia
function rewrite_with_block(block)
    block_expressions = block.args
    reconvert_docstrings!(block_expressions)

    previous_df = gensym()
    header = []
    body = []
    did_first = false
    for expr in block_expressions
        # the first non-LineNumberNode is the DataFrame to activate
        if !(did_first || expr isa LineNumberNode)
            did_first = true
            push!(header, :(local $previous_df = getdf()))
            push!(header, :(setdf($expr)))
            continue
        end
        push!(body, expr)
    end
    did_first || error("No expressions found in with block.")

    quote
        $(header...)
        try
            $(body...)
        finally
            setdf($previous_df)
        end
    end |> esc
end
```

Notes:
- The old `isempty(...) || (...) && error(...)` guard had a precedence bug; the new
  `did_first || error(...)` check replaces it.
- `@with!` composes with this unchanged (it assigns the block's value).
- The teardown closure and its `|>` piping are gone entirely.

Add to `test/With.jl`:
```julia
@testset "previous df is restored when the block throws" begin
    outer = DataFrame(a = [1])
    setdf(outer)
    inner = DataFrame(x = [1, 2])
    @test_throws Exception @with inner begin
        error("boom")
    end
    @test getdf().a == [1]
    setdf(nothing)
end
```

### 4b. Move runtime checks inside the generated code

In `src/macros.jl`:

- **`@use`**: keep the two syntactic checks (argument count, only-`clear` option) at
  expansion time. Move the "already have a df" check into the emitted code:
  ```julia
  macro use(exprs...)
      command = parse(exprs, :use)
      length(command.arguments) == 1 || ArgumentError("@use takes a single file name as an argument:\n@use \"filename.dta\"[, clear]") |> throw
      isempty(filter(x -> x != :clear, command.options)) || ArgumentError("Invalid options $(string.(command.options)). Correct syntax:\n@use \"filename.dta\"[, clear]") |> throw
      fname = command.arguments[1]
      clear = :clear in command.options
      quote
          isnothing(getdf()) || $clear || throw(ArgumentError("There is already a global data frame set. If you want to replace it, use the \", clear\" option."))
          println("$(Kezdi.prompt())$($command)\n")
          Kezdi.use($fname)
      end |> esc
  end
  ```
- **`@save`**: same treatment; `getdf()` and `ispath(fname)` checks go into the quote
  (this also fixes `@save` with a non-literal filename expression, where `ispath(fname)`
  at expansion time inspected an `Expr`):
  ```julia
  macro save(exprs...)
      command = parse(exprs, :save)
      length(command.arguments) == 1 || ArgumentError("@save takes a single file name as an argument:\n@save \"filename.dta\"") |> throw
      fname = command.arguments[1]
      replace = :replace in command.options
      quote
          isnothing(getdf()) && throw(ArgumentError("There is no data frame to save."))
          ispath($fname) && !$replace && throw(ArgumentError("File $($fname) already exists."))
          println("$(Kezdi.prompt())$($command)\n")
          Kezdi.save($fname)
      end |> esc
  end
  ```
- **`@append`**: move the `isnothing(getdf())` check into the quote the same way.

Check `test/commands.jl` for tests of these three macros: where a test asserts that the
error is thrown, it may currently rely on expansion-time throwing (a macro that throws
at expansion raises `LoadError` wrapping the `ArgumentError`). With the checks moved to
run time the error is a plain `ArgumentError`. Update any `@test_throws LoadError` to
`@test_throws ArgumentError` for these cases (grep: `grep -n "test_throws" test/commands.jl`).

### 4c. Stop touching the global logger

- Delete line 1 of `src/parse.jl`:
  `global_logger(Logging.ConsoleLogger(stderr, Logging.Info))`.
  (Top-level code runs at *precompile* time, so this never did what it looks like — and
  a library must not override the user's logger anyway. The `@debug` calls in the file
  work without it; `@debug` is available from Base.)
- Remove `using Logging` from `src/Kezdi.jl` and remove `Logging` from `[deps]` and
  `[compat]` in `Project.toml`.
- `test/runtests.jl` has `using Logging`; check whether tests actually use Logging
  symbols (`grep -n "Logging\.\|with_logger\|ConsoleLogger\|@test_logs" test/`). If yes,
  add `Logging` to `[extras]` and the `test` target (it is a stdlib but still must be
  declared). If no, delete the `using Logging` line.

**Acceptance:** `Pkg.test()` green, including the new `@with` exception test.

**Commit:** `Make @with exception-safe; move @use/@save/@append checks to run time; stop setting global logger`

---

## Phase 5 — Remove `Main.eval` + `methodswith` from macro expansion (the big one)

**Goal:** macro expansion must be a pure syntax transformation. The decision "call `f`
on the whole column vs. broadcast `f` over its elements" moves from expansion time
(where it currently uses `Main.eval` + `InteractiveUtils.methodswith`, `src/codegen.jl:238-245`)
to run time, where it is made by inspecting the *function value* — world-age correct,
precompile-safe, and independent of what happens to be defined in `Main`.

### 5a. Current semantics to preserve (read first)

For a call `f(args...)` in a user expression, `vectorize_function_calls` currently
chooses one of three shapes:

| decision (expansion time, via methodswith on Main.eval(fname)) | emitted code |
|---|---|
| `f` has a method mentioning `Vector`/supertype (excl. `Any`) in its signature, or `f ∈ DO_NOT_VECTORIZE` | `f(keep_only_values(arg1), keep_only_values(arg2), ...)` |
| else, `f` has a method mentioning `Missing`/supertype (excl. `Any`), or `f == ismissing` | `f.(args...)` |
| else | `passmissing(f).(args...)` |

Special cases that stay at expansion time (they are purely syntactic):
operators (`x + y` → `x .+ y`), syntactic operators (`&&` → `.&&`), already-dotted
calls (`log.(x)` untouched), the `~f(x)` do-not-vectorize escape (→ plain `f(x)`),
and `getindex` (`ALWAYS_VECTORIZE` → broadcast).

### 5b. New runtime helpers

Add to `src/functions.jl`:

```julia
"""
    signature_mentions(f, T) -> Bool

Return `true` if any method of `f` has an argument annotated with `T` or a supertype
of `T`, excluding `Any`. Runtime replacement for
`InteractiveUtils.methodswith(T, f; supertypes=true)`.
"""
function signature_mentions(@nospecialize(f), @nospecialize(T::Type))
    for m in methods(f)
        sig = Base.unwrap_unionall(m.sig)
        sig isa DataType || continue
        for p in sig.parameters[2:end]
            p isa Core.TypeofVararg && (p = Base.unwrapva(p))
            p isa TypeVar && (p = p.ub)
            p === Any && continue
            p isa Type || continue
            T <: p && return true
        end
    end
    return false
end

operates_on_vector(@nospecialize(f)) = signature_mentions(f, Vector)
operates_on_missing(@nospecialize(f)) = f === ismissing || f === anymissing || signature_mentions(f, Missing)

"""
    apply_function(f, args...)

Apply `f` the way Kezdi commands need it: functions that operate on vectors (like
`mean`) receive the columns with missings/NaN/Inf removed; element-wise functions are
broadcast, wrapped in `passmissing` unless they handle `missing` themselves.
"""
function apply_function(f, args...)
    f === getindex && return f.(args...)
    operates_on_vector(f) && return f(map(keep_only_values, args)...)
    operates_on_missing(f) && return f.(args...)
    return passmissing(f).(args...)
end
```

Export `apply_function` alongside the other function exports in `src/Kezdi.jl`
(generated code references it as `Kezdi.apply_function`, but exporting makes the
expanded code readable and testable).

### 5c. Rewire codegen

In `src/codegen.jl`:

1. In `vectorize_function_calls(expr::Expr)`, keep the following branches exactly as
   they are: the `ismissing`→`anymissing` rewrite from Phase 3, the syntactic-operator
   branch, the operator-as-call branch, the `~` escape branch, and the already-dotted
   (`expr.head == Symbol(".")`) branch.
2. Replace the two remaining branches — the `tovectorize(expr) && return ...
   passmissing ...` branch and the final `keep_only_values` fallback line — with a
   single emission:
   ```julia
   # every remaining plain call: decide vectorization at run time
   return Expr(:call, :(Kezdi.apply_function), fname,
       vectorize_function_calls.(expr.args[2:end])...)
   ```
3. Delete from `src/codegen.jl`: `tovectorize` (all three methods),
   `operates_on_type`, and the old expression-based `operates_on_missing` /
   `operates_on_vector` definitions (the runtime ones in `functions.jl` replace them).
   Keep `is_operator`, `is_dotted_operator`, `isfunctioncall`, etc.
4. Delete `DO_NOT_VECTORIZE` and `ALWAYS_VECTORIZE` from `src/consts.jl`
   (`signature_mentions` covers `sum`/`mean`/`minimum`/`maximum`/`rowcount`/`distinct`,
   and `getindex` is special-cased in `apply_function`).
5. Remove `using InteractiveUtils` from `src/Kezdi.jl` and remove `InteractiveUtils`
   from `[deps]` and `[compat]` in `Project.toml`.
6. `grep -rn "Main.eval\|methodswith\|InteractiveUtils" src/` must return nothing.

### 5d. Update tests

In `test/codegen.jl`:

1. **"Vectorize function calls" testset** — expected shapes change. Examples of the new
   expectations (apply the same pattern to every case):
   ```julia
   @test_expr vectorize_function_calls(:(log(x))) == :(Kezdi.apply_function(log, x))
   @test_expr vectorize_function_calls(:(x + y)) == :(x .+ y)                     # unchanged
   @test_expr vectorize_function_calls(:(mean(x))) == :(Kezdi.apply_function(mean, x))
   @test_expr vectorize_function_calls(:(mean(x) + log(y))) ==
       :(Kezdi.apply_function(mean, x) .+ Kezdi.apply_function(log, y))
   @test_expr vectorize_function_calls(:(log.(x))) == :(log.(x))                  # unchanged
   @test_expr vectorize_function_calls(:(~log(x))) == :(log(x))                   # unchanged
   ```
   The "Functions in other modules" cases become
   `:(Kezdi.apply_function(MyModule.myfunc, x))` etc.
2. **Replace the `operates_on_type` testset** with runtime-semantics tests:
   ```julia
   @testset "runtime vectorization decisions" begin
       @test Kezdi.operates_on_vector(mean)
       @test Kezdi.operates_on_vector(sum)
       @test Kezdi.operates_on_vector(wsum)          # StatsBase, weighted-sum methods mention vectors
       @test !Kezdi.operates_on_vector(log)
       @test Kezdi.operates_on_missing(log)          # Base defines log(::Missing)
       @test !Kezdi.operates_on_missing(sum)
       @test Kezdi.operates_on_vector(MyModule.myaggreg)
       @test Kezdi.operates_on_missing(MyModule.mymiss)
       @test !Kezdi.operates_on_vector(MyModule.myfunc)

       # comparisons involving missing need isequal
       @test isequal(Kezdi.apply_function(log, [1.0, missing]), [0.0, missing])
       @test Kezdi.apply_function(mean, [1.0, missing, 3.0]) == 2.0
       @test isequal(Kezdi.apply_function(Dates.year, [Date(2020,1,1), missing]), [2020, missing])
   end
   ```
3. The existing end-to-end tests in `test/commands.jl` (the real acceptance bar) must
   pass **unchanged**. If any fails, the runtime decision diverges from the old
   expansion-time decision for that function — fix `apply_function`/`signature_mentions`,
   not the test.
4. Update `docs/src/developing.md`: it shows `@macroexpand` output of the old code.
   Regenerate the shown expansion by running the same `@macroexpand` call on the new
   code and paste the (gensym-renamed) result, or simplify the prose to describe the new
   `Kezdi.apply_function` shape.

**Acceptance:** full suite green; the greps in 5c.6 empty; `julia --project=. -e 'using Kezdi'`
still loads (InteractiveUtils gone from deps).

**Commit:** `Decide vectorization at run time; drop Main.eval/methodswith from macro expansion`

---

## Phase 6 — Precompilation workload and `public` API

**Goal:** cache native code for the whole parse→rewrite pipeline (package images do
this since 1.9, but only for code that a workload actually compiles), and declare the
supported non-exported API.

**Files:** `Project.toml`, `src/Kezdi.jl`, new `src/precompile.jl`

1. Add `PrecompileTools` to `[deps]`
   (`PrecompileTools = "aea7be01-6a6a-4083-8856-8a6e6704d82a"`) and `[compat]`
   (`PrecompileTools = "1"`).
2. Create `src/precompile.jl`:
   ```julia
   using PrecompileTools

   @setup_workload begin
       _df = DataFrame(x = [1.0, 2.0, missing], s = ["a", "b", "c"], g = [1, 1, 2])
       @compile_workload begin
           # expansion pipeline: one representative parse+rewrite per command.
           # An @if condition arrives from the macro as a :macrocall Expr:
           _if = (cond -> Expr(:macrocall, Symbol("@if"), LineNumberNode(0), cond))
           rewrite(parse((:(y = x + 1),), :generate))
           rewrite(parse((:(y = x + 1), _if(:(x > 2))), :generate))
           rewrite(parse((:(x = 2 * x),), :replace))
           rewrite(parse((:x, _if(:(x < 2))), :keep))
           rewrite(parse((:s,), :drop))
           rewrite(parse((:(m = mean(x)), :(by(g)),), :collapse))
           rewrite(parse((:(m = sum(x)), :(by(g)),), :egen))
           rewrite(parse((:x,), :sort))
           rewrite(parse((:x,), :order))
           rewrite(parse((:x, :g), :tabulate))
           rewrite(parse((:x,), :summarize))
           rewrite(parse((:x, :g), :regress))
           rewrite(parse((), :count))
           rewrite(parse((:x,), :list))
           rewrite(parse((), :describe))
           rewrite(parse((:x, :s), :mvencode))
           # runtime helpers
           setdf(_df)
           apply_function(log, [1.0, missing])
           apply_function(mean, [1.0, missing])
           Kezdi.summarize(getdf(), :x)
           Kezdi.tabulate(getdf(), [:g])
           Kezdi._describe(getdf())
           setdf(nothing)
       end
   end
   ```
   Add `include("precompile.jl")` as the last include in `src/Kezdi.jl` (after the
   `With` include). If any single `rewrite(parse(...))` line errors during precompile,
   fix the tuple to match how that macro actually calls `parse` (compare with
   `src/macros.jl`) — or drop that one line; do not fight it.
3. **`public` declarations** (Julia 1.11+; harmless no-op guard on 1.10). Add to
   `src/Kezdi.jl` after the exports:
   ```julia
   @static if VERSION >= v"1.11"
       # `public` is a keyword only from 1.11; eval-parse keeps 1.10 parsing this file
       eval(Meta.parse("public use, save, summarize, tabulate, prompt"))
   end
   ```
4. Re-measure `@time using Kezdi` (second run) and first-command latency
   (`@time @macroexpand @generate y = x + 1` in a fresh session with a df set); report
   before/after numbers in the PR description.

**Acceptance:** package precompiles without warnings; suite green; load-time numbers reported.

**Commit:** `Add PrecompileTools workload and public API declarations`

---

## Phase 7 — Small correctness/performance cleanups

Each item is independent; do them in one commit. Run tests after each item.

**Files:** `src/functions.jl`, `src/codegen.jl`, `src/commands.jl`, `src/structs.jl`, `src/macros.jl`, tests, docs

1. **`keep_only_values` single pass** (`src/functions.jl`):
   ```julia
   keep_only_values(x) = collect(Iterators.filter(isvalue, skipmissing(x)))
   ```
2. **`isvalue` simplifications** (`src/functions.jl`):
   ```julia
   isvalue(x::Number) = isfinite(x)
   isvalue(args...) = all(isvalue, args)
   ```
   (`isfinite(x)` ≡ `!isinf(x) && !isnan(x)`; `all(isvalue, args)` avoids the broadcast
   temporary.)
3. **`build_bitmask` via `coalesce`** (`src/codegen.jl`). The `falses(nrow(df)) .| ...`
   trick exists to (a) coerce `missing` to `false` and (b) expand a *scalar* condition
   (e.g. `@if 2 < 4`) to a full-length vector. Preserve both explicitly:
   ```julia
   # in functions.jl:
   tomask(m::AbstractVector, n::Int) = coalesce.(m, false)
   tomask(m, n::Int) = fill(coalesce(m, false), n)   # scalar condition, e.g. @if 2 < 4

   # in codegen.jl:
   function build_bitmask(df::Any, condition::Any)::Expr
       condition = condition isa Nothing ? true : condition
       mask = replace_column_references(df, condition) |> vectorize_function_calls
       :(Kezdi.tomask($mask, nrow($df)))
   end
   ```
   Update `test/codegen.jl` "Bitmask" testset accordingly:
   ```julia
   @test_expr Kezdi.build_bitmask(:df, :(x < 4)) == :(Kezdi.tomask(df.x .< 4, nrow(df)))
   @test eval(Kezdi.build_bitmask(:(DataFrame(x = [1, 2, missing, 4])), :(2 < 4))) == [true, true, true, true]
   ```
   Also update the expansion examples in `docs/src/developing.md` that show
   `Missings.replace`. Check whether `Missings` is still needed in `[deps]` afterwards:
   `grep -rn "Missings\.\|passmissing" src/` — `passmissing` comes from Missings, so the
   dependency stays; only remove it if nothing matches.
4. **`process` closure in `generate_command`** (`src/codegen.jl`): replace the method
   definition inside the `if` with a plain assignment so `process` is only ever
   rebound, never given methods:
   ```julia
   if :replace_variables in options
       process = x -> replace_column_references(sdf, x)
   end
   ```
5. **Typos:** rename `combine_epxression` → `combine_expression`
   (`src/commands.jl`, both occurrence sites), fix "inspectiung" → "inspecting"
   (`src/macros.jl`), fix the stray backticks in the `keep_only_values` docstring
   ("`missing`` values ... `Inf`a" → "`missing` values ... `Inf`").
6. **Duplicate usings:** delete `using DataFrames`, `using Statistics`,
   `using StatsBase` from `src/structs.jl` (already loaded at module level).
7. **Rename internal `parse`** → `parse_command` to stop shadowing `Base.parse`
   (`src/parse.jl` both methods, all call sites in `src/macros.jl`, the workload in
   `src/precompile.jl` from Phase 6, and the alias in `test/runtests.jl`). After this,
   the explicit `Base.parse(Int, ...)` in `src/commands.jl:21` can become plain
   `parse(Int, ...)` — but leaving it qualified is also fine.

**Acceptance:** suite green.

**Commit:** `Small cleanups: single-pass keep_only_values, coalesce-based bitmask, typos, parse_command rename`

---

## Phase 8 — Final verification

1. Full matrix locally if possible (`juliaup` makes this easy):
   ```sh
   julia +1.10 --project=. -e 'using Pkg; Pkg.test()'
   julia +1.11 --project=. -e 'using Pkg; Pkg.test()'
   julia +1.12 --project=. -e 'using Pkg; Pkg.test()'
   ```
2. `grep -rn "Main.eval\|methodswith\|InteractiveUtils\|Expronicon" src/ Project.toml` → empty.
3. Docs build: `julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); include("docs/make.jl")'`
   (doctests show command output; if a doctest fails because generated code *shape*
   changed but the *result* is identical, update the doctest output).
4. Bump `version` in `Project.toml` to `0.6.0` (breaking-ish: `Base.ismissing` piracy
   removal, minimum Julia 1.10).
5. Report in the PR: before/after `@time using Kezdi`, before/after first-command
   latency, and the list of behavior changes (multi-arg `ismissing` outside commands;
   errors from `@use`/`@save`/`@append` now thrown at run time).

---

## Explicitly out of scope (do not do)

- Switching `@with` to `ScopedValues` (requires min Julia 1.11; revisit when 1.10
  support is dropped).
- Package extensions for FixedEffectModels/ReadStatTables (the batteries-included
  reexport design is intentional).
- Any change to `setdf` copy semantics.
- JET.jl CI integration (nice-to-have; separate PR).
- Restructuring the `Node`/`Command` parser types.
