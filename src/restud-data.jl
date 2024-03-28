# TODO: 
#1. get tree of repo, the api says it can be queried by branch and can be done recursively
#2. get .do file paths from tree

using HTTP, JSON3
GITHUB_TOKEN = readline(open(".github_token", "r"))

CREDENTIALS = [
    "Accept" => "application/vnd.github+json", 
    "Authorization" => "Bearer $GITHUB_TOKEN", 
    "X-GitHub-Api-Version" => "2022-11-28",
    ]

function get_paged_data(url::String)
    next_pattern = r"rel=\"next\""
    link_pattern = r".*<(.+)>; rel=\"next\".*"
    page_remains = true
    repo_list = Dict([(:name,[]), (:default_branch, [])])

    while page_remains
        r = HTTP.get(url, headers=CREDENTIALS)
        page = JSON3.read(r.body)

        for repo in page
            push!(repo_list[:name], repo.name)
            push!(repo_list[:default_branch], repo.default_branch)
        end

        links = r.headers[findall(x->x[1]=="Link", r.headers)]
        url = replace(links[1][2], link_pattern => s"\1")

        page_remains = occursin(next_pattern, links[1][2])
    end
    return repo_list
end


repo_list_url = "http://api.github.com/orgs/restud-replication-packages/repos"
repos = get_paged_data(repo_list_url)
println(repos)