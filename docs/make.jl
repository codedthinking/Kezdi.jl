using Documenter, Kezdi

DocMeta.setdocmeta!(Kezdi, :DocTestSetup, :(using Kezdi); recursive=true)

makedocs(;
    modules=[Kezdi],
    authors="Miklos Koren <miklos.koren@gmail.com>, Gergely Attila Kiss <corra971407@gmail.com>",
    sitename="Kezdi.jl",
    format=Documenter.HTML(;
        canonical="https://docs.koren.dev/Kezdi.jl",
        edit_link="main",
        assets = [
            asset("https://dcas.codedthinking.workers.dev/sj/script.js", class=:js, 
            attributes=Dict(
                Symbol("data-domain") => "koren.dev", 
                Symbol("data-api") => "https://dcas.codedthinking.workers.dev/ipa/event",
                :defer => ""))
        ],   
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "reference.md",
        "Contributing" => "developing.md",
    ],
)

# url of target repo
repo = "github.com/codedthinking/docs.koren.dev.git"

# You have to override the corresponding environment variable that
# deplodocs uses to determine if it is deploying to the correct repository.
# For GitHub, it's the GITHUB_REPOSITORY variable:
withenv("GITHUB_REPOSITORY" => repo) do
  deploydocs(;
    repo=repo,
    dirname="Kezdi.jl",)
end
