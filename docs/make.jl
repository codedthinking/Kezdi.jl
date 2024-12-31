using Documenter, Kezdi

DocMeta.setdocmeta!(Kezdi, :DocTestSetup, :(using Kezdi); recursive=true)

makedocs(;
    modules=[Kezdi],
    authors="Miklos Koren <miklos.koren@gmail.com>, Gergely Attila Kiss <corra971407@gmail.com>",
    sitename="Kezdi.jl",
    format=Documenter.HTML(;
        canonical="https://docs.koren.dev/Kezdi.jl",
        edit_link="main",
        assets=String[],
        scripts = [
            "https://dcas.codedthinking.workers.dev/sj/script.js"
        ],
        script_attributes = Dict(
            "https://dcas.codedthinking.workers.dev/sj/script.js" => Dict(
                "data-domain" => "koren.dev",
                "data-api" => "https://dcas.codedthinking.workers.dev/ipa/event",
                "defer" => ""
            )
        )
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