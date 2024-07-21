using Documenter, Kezdi

DocMeta.setdocmeta!(Kezdi, :DocTestSetup, :(using Kezdi); recursive=true)

makedocs(;
    modules=[Kezdi],
    authors="Miklos Koren <miklos.koren@gmail.com>, Gergely Attila Kiss <corra971407@gmail.com>",
    sitename="Kezdi.jl",
    format=Documenter.HTML(;
        canonical="https://codedthinking.github.io/Kezdi.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md",
        "Contributing" => "developing.md",
    ],
)

deploydocs(;
    repo="github.com/codedthinking/Kezdi.jl",
    devbranch="main",
)