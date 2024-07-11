using HTTP, JSON3, Base64
GITHUB_TOKEN = readline(open(".github_token", "r"))

CREDENTIALS = [
    "Accept" => "application/vnd.github+json", 
    "Authorization" => "Bearer $GITHUB_TOKEN", 
    "X-GitHub-Api-Version" => "2022-11-28",
    ]

function get_repos(url::String)
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

function get_tree_sha(url::String)
    r = HTTP.get(url, headers=CREDENTIALS)
    body = JSON3.read(r.body)
    return body[:commit][:sha]
end

function get_paths(url::String)
    r = HTTP.get(url, headers=CREDENTIALS)
    body = JSON3.read(r.body)
    tree = body[:tree]
    return extract_paths(tree)
end

function extract_paths(tree::JSON3.Array)
    paths = [
        path[:path] 
        for path in tree if endswith(path[:path], ".do") 
        ]
    return paths
end

function get_dofile(url::String)
    r = HTTP.get(url, headers=CREDENTIALS)
    body = JSON3.read(r.body)
    script = String(base64decode(body[:content]))
    return script
end

function write_file(script::String, name::AbstractString)
    open(name, "w") do file
        write(file, script)
    end
end


## A simple example
repo_list_url = "http://api.github.com/orgs/restud-replication-packages/repos"
repos = get_repos(repo_list_url)
repo = (repos[:name][1], repos[:default_branch][1])
repo_branch_url = "http://api.github.com/repos/restud-replication-packages/$(repo[1])/branches/$(repo[2])"
sha = get_tree_sha(repo_branch_url)
tree_url = "http://api.github.com/repos/restud-replication-packages/$(repo[1])/git/trees/$(sha)?recursive=1"
dofiles = get_paths(tree_url)
dofile = dofiles[1]
dofile = replace(dofile, r" " => s"%20")
file_url = "http://api.github.com/repos/restud-replication-packages/$(repo[1])/contents/$dofile"
file = get_dofile(file_url)
write_file(file, last(split(dofile, "/")))
