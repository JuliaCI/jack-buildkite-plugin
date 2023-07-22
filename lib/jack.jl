using Pkg, JLLPrefixes

# Helper to extract buildkite environment arrays
function extract_env_array(prefix::String)
    envname(idx::Int) = string(prefix, "_", idx)
    envname(idx::Int, suffix) = string(prefix, "_", idx, "_", suffix)

    idx = 0
    array = PackageSpec[]
    while haskey(ENV, envname(idx)) || haskey(ENV, envname(idx, "NAME"))
        # We support multiple formats of JLL specification, that map to different `PackageSpec`'s:

        # - "Foo_jll"
        # will map to `PackageSpec(name = "Foo_jll")`, so no version constraints at all
        if haskey(ENV, envname(idx))
            push!(array,
                PackageSpec(
                    name = ENV[envname(idx)],
                ),
            )

        # - name: "Foo_jll"
        #   version: "v1.4.0"
        # will map to `PackageSpec(name = "Foo_jll", version="v1.4.0")`.
        elseif haskey(ENV, envname(idx, "NAME")) && haskey(ENV, envname(idx, "VERSION"))
            push!(array,
                PackageSpec(
                    name = ENV[envname(idx, "NAME")],
                    version = VersionNumber(ENV[envname(idx, "VERSION")]),
                ),
            )

        # - name: "Foo_jll"
        #   url: "https://github.com/fooifiers/Foo_jll.jl"
        #   rev: "1a2b3c4d"
        # will map to `PackageSpec(name = "Foo_jll", repo=GitRepo(source="https://github.com/fooifiers/Foo_jll.jl", rev="1a2b3c4d"))
        # Note that `rev` is optional.
        elseif haskey(ENV, envname(idx, "NAME")) && haskey(ENV, envname(idx, "URL"))
            if haskey(ENV, envname(idx, "REV"))
                repo = Pkg.Types.GitRepo(source=ENV[envname(idx, "URL")], rev=ENV[envname(idx, "REV")])
            else
                repo = Pkg.Types.GitRepo(source=ENV[envname(idx, "URL")])
            end
            push!(array,
                PackageSpec(;
                    name = ENV[envname(idx, "NAME")],
                    repo = repo,
                ),
            )
        end
        idx += 1
    end
    return array
end

prefix = get(ENV, "BUILDKITE_PLUGIN_JACK_PREFIX", joinpath(homedir(), "jack"))
clones_dir = get(ENV, "BUILDKITE_PLUGIN_JACK_GIT_CLONES_DIR", joinpath(prefix, "..", "jack-clones"))
install = extract_env_array("BUILDKITE_PLUGIN_JACK_INSTALL")
strategy = Symbol(get(ENV, "BUILDKITE_PLUGIN_JACK_STRATEGY", "auto"))

# Tell JLLPrefixes to store its git clones in `clones_dir`
JLLPrefixes.set_git_clones_dir!(clones_dir)

@assert strategy in [:copy, :hardlink, :symlink, :auto] """
Invalid `strategy` specified. Valid values are `copy`, `symlink` and `hardlink`."""

mkpath(prefix) # create the directory if it doesn't already exist.

println("--- Collecting Artifacts")
artifact_paths = collect_artifact_paths(install)
display(artifact_paths)

println("--- Deploying artifacts", prefix, strategy)
deploy_artifact_paths(prefix, artifact_paths; strategy)
