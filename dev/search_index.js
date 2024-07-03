var documenterSearchIndex = {"docs":
[{"location":"reference/","page":"Reference","title":"Reference","text":"CurrentModule = Kezdi","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"","category":"page"},{"location":"reference/","page":"Reference","title":"Reference","text":"Modules = [Kezdi]","category":"page"},{"location":"reference/#Kezdi.@collapse-Tuple","page":"Reference","title":"Kezdi.@collapse","text":"@collapse df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nCollapse df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@count-Tuple","page":"Reference","title":"Kezdi.@count","text":"@count df [@if condition]\n\nCount the number of rows for which the condition is true. If condition is not provided, the total number of rows is counted.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@drop-Tuple","page":"Reference","title":"Kezdi.@drop","text":"@drop df y1 y2 ...\n\nor     @drop df [@if condition]    \n\nDrop the variables y1, y2, etc. from df. If condition is provided, the rows for which the condition is true are dropped.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@egen-Tuple","page":"Reference","title":"Kezdi.@egen","text":"@egen df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nGenerate new variables in df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@generate-Tuple","page":"Reference","title":"Kezdi.@generate","text":"@generate df y = expr [@if condition]\n\nCreate a new variable y in df by evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. \n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@keep-Tuple","page":"Reference","title":"Kezdi.@keep","text":"@keep df y1 y2 ... [@if condition]\n\nKeep only the variables y1, y2, etc. in df. If condition is provided, only the rows for which the condition is true are kept.  \n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@regress-Tuple","page":"Reference","title":"Kezdi.@regress","text":"@regress df y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]\n\nEstimate a regression model in df with dependent variable y and independent variables x1, x2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If robust is provided, robust standard errors are calculated. If cluster is provided, clustered standard errors are calculated.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@replace-Tuple","page":"Reference","title":"Kezdi.@replace","text":"@replace df y = expr [@if condition]\n\nReplace the values of y in df with the result of evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@summarize-Tuple","page":"Reference","title":"Kezdi.@summarize","text":"@summarize df y [@if condition]\n\nSummarize the variable y in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Kezdi.@tabulate-Tuple","page":"Reference","title":"Kezdi.@tabulate","text":"@tabulate df y1 y2 ... [@if condition]\n\nCreate a frequency table for the variables y1, y2, etc. in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = Kezdi","category":"page"},{"location":"#Kezdi.jl-Documentation","page":"Home","title":"Kezdi.jl Documentation","text":"","category":"section"},{"location":"#Getting-started","page":"Home","title":"Getting started","text":"","category":"section"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Pkg; Pkg.add(\"https://github.com/codedthinking/Kezdi.jl#0.4-beta\")","category":"page"},{"location":"#Example","page":"Home","title":"Example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Kezdi\ndf = CSV.read(\"data.csv\", DataFrame)\n\n@with df ","category":"page"},{"location":"","page":"Home","title":"Home","text":"<script async data-uid=\"62d7ebb237\" src=\"https://relentless-producer-1210.ck.page/62d7ebb237/index.js\"></script>","category":"page"},{"location":"#Benefits-of-using-Kezdi.jl","page":"Home","title":"Benefits of using Kezdi.jl","text":"","category":"section"},{"location":"#Speed","page":"Home","title":"Speed","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Command Stata Julia 1st run Julia 2nd run Speedup\n@egen 4.90s 1.60s 0.41s 10x\n@collapse 0.92s 0.18s 0.13s 8x\n@regress 0.89s 1.93s 0.16s 6x\n@tabulate 2.14s 0.46s 0.10s 20x\n@summarize 10.40s 0.58s 0.37s 28x","category":"page"},{"location":"#Commands","page":"Home","title":"Commands","text":"","category":"section"},{"location":"#Filtering-columns-and-rows","page":"Home","title":"Filtering columns and rows","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@keep","category":"page"},{"location":"#Kezdi.@keep","page":"Home","title":"Kezdi.@keep","text":"@keep df y1 y2 ... [@if condition]\n\nKeep only the variables y1, y2, etc. in df. If condition is provided, only the rows for which the condition is true are kept.  \n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@drop","category":"page"},{"location":"#Kezdi.@drop","page":"Home","title":"Kezdi.@drop","text":"@drop df y1 y2 ...\n\nor     @drop df [@if condition]    \n\nDrop the variables y1, y2, etc. from df. If condition is provided, the rows for which the condition is true are dropped.\n\n\n\n\n\n","category":"macro"},{"location":"#Modifying-columns","page":"Home","title":"Modifying columns","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@generate","category":"page"},{"location":"#Kezdi.@generate","page":"Home","title":"Kezdi.@generate","text":"@generate df y = expr [@if condition]\n\nCreate a new variable y in df by evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be missing. \n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@replace","category":"page"},{"location":"#Kezdi.@replace","page":"Home","title":"Kezdi.@replace","text":"@replace df y = expr [@if condition]\n\nReplace the values of y in df with the result of evaluating expr. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variable will be left unchanged.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@egen","category":"page"},{"location":"#Kezdi.@egen","page":"Home","title":"Kezdi.@egen","text":"@egen df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nGenerate new variables in df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. When the condition is false, the variables will be missing. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"#Grouping-data","page":"Home","title":"Grouping data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@collapse","category":"page"},{"location":"#Kezdi.@collapse","page":"Home","title":"Kezdi.@collapse","text":"@collapse df y1 = expr1 y2 = expr2 ... [@if condition], [by(group1, group2, ...)]\n\nCollapse df by evaluating expressions expr1, expr2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If by is provided, the operation is executed by group.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@tabulate","category":"page"},{"location":"#Kezdi.@tabulate","page":"Home","title":"Kezdi.@tabulate","text":"@tabulate df y1 y2 ... [@if condition]\n\nCreate a frequency table for the variables y1, y2, etc. in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@summarize","category":"page"},{"location":"#Kezdi.@summarize","page":"Home","title":"Kezdi.@summarize","text":"@summarize df y [@if condition]\n\nSummarize the variable y in df. If condition is provided, the operation is executed only on rows for which the condition is true.\n\n\n\n\n\n","category":"macro"},{"location":"","page":"Home","title":"Home","text":"@regress","category":"page"},{"location":"#Kezdi.@regress","page":"Home","title":"Kezdi.@regress","text":"@regress df y x1 x2 ... [@if condition], [robust] [cluster(var1, var2, ...)]\n\nEstimate a regression model in df with dependent variable y and independent variables x1, x2, etc. If condition is provided, the operation is executed only on rows for which the condition is true. If robust is provided, robust standard errors are calculated. If cluster is provided, clustered standard errors are calculated.\n\n\n\n\n\n","category":"macro"},{"location":"#With-Module","page":"Home","title":"With Module","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"@with","category":"page"},{"location":"#Kezdi.With.@with","page":"Home","title":"Kezdi.With.@with","text":"@with(expr, exprs...)\n\nRewrites a series of expressions into a with, where the result of one expression is inserted into the next expression following certain rules.\n\nRule 1\n\nAny expr that is a begin ... end block is flattened. For example, these two pseudocodes are equivalent:\n\n@with a b c d e f\n\n@with a begin\n    b\n    c\n    d\nend e f\n\nRule 2\n\nAny expression but the first (in the flattened representation) will have the preceding result inserted as its first argument, unless at least one underscore _ is present. In that case, all underscores will be replaced with the preceding result.\n\nIf the expression is a symbol, the symbol is treated equivalently to a function call.\n\nFor example, the following code block\n\n@with begin\n    x\n    f()\n    @g()\n    h\n    @i\n    j(123, _)\n    k(_, 123, _)\nend\n\nis equivalent to\n\nbegin\n    local temp1 = f(x)\n    local temp2 = @g(temp1)\n    local temp3 = h(temp2)\n    local temp4 = @i(temp3)\n    local temp5 = j(123, temp4)\n    local temp6 = k(temp5, 123, temp5)\nend\n\nRule 3\n\nAn expression that begins with @aside does not pass its result on to the following expression. Instead, the result of the previous expression will be passed on. This is meant for inspecting the state of the with. The expression within @aside will not get the previous result auto-inserted, you can use underscores to reference it.\n\n@with begin\n    [1, 2, 3]\n    filter(isodd, _)\n    @aside @info \"There are $(length(_)) elements after filtering\"\n    sum\nend\n\nRule 4\n\nIt is allowed to start an expression with a variable assignment. In this case, the usual insertion rules apply to the right-hand side of that assignment. This can be used to store intermediate results.\n\n@with begin\n    [1, 2, 3]\n    filtered = filter(isodd, _)\n    sum\nend\n\nfiltered == [1, 3]\n\nRule 5\n\nThe @. macro may be used with a symbol to broadcast that function over the preceding result.\n\n@with begin\n    [1, 2, 3]\n    @. sqrt\nend\n\nis equivalent to\n\n@with begin\n    [1, 2, 3]\n    sqrt.(_)\nend\n\n\n\n\n\n","category":"macro"},{"location":"#Gotchas-for-Julia-users","page":"Home","title":"Gotchas for Julia users","text":"","category":"section"},{"location":"#Everything-is-a-macro","page":"Home","title":"Everything is a macro","text":"","category":"section"},{"location":"#Comma-is-used-for-options","page":"Home","title":"Comma is used for options","text":"","category":"section"},{"location":"#Automatic-variable-name-substitution","page":"Home","title":"Automatic variable name substitution","text":"","category":"section"},{"location":"#Automatic-vectorization","page":"Home","title":"Automatic vectorization","text":"","category":"section"},{"location":"#Handling-missing-values","page":"Home","title":"Handling missing values","text":"","category":"section"},{"location":"#Gotchas-for-Stata-users","page":"Home","title":"Gotchas for Stata users","text":"","category":"section"},{"location":"#All-commands-begin-with-@","page":"Home","title":"All commands begin with @","text":"","category":"section"},{"location":"#@collapse-has-same-syntax-as-@egen","page":"Home","title":"@collapse has same syntax as @egen","text":"","category":"section"}]
}
