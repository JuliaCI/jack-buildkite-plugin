using Pkg, JLLPrefixes

# Helper to extract buildkite environment arrays
function extract_env_array(prefix::String)
    envname(idx::Int) = string(prefix, "_", idx)

    idx = 0
    array = PackageSpec[]
    while haskey(ENV, envname(idx)) || (haskey(ENV, string(envname(idx), "_NAME" )) && haskey(ENV, string(envname(idx), "_VERSION" )))
        if haskey(ENV, envname(idx))
            push!(array, PackageSpec(name = ENV[envname(idx)]))
        elseif (haskey(ENV, string(envname(idx), "_NAME" )) && haskey(ENV, string(envname(idx), "_VERSION" )))
            push!(array, PackageSpec(name = ENV[string(envname(idx), "_NAME")], version = VersionNumber(ENV[string(envname(idx), "_VERSION")])))
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

println("--- Deploying strategy for prefix")
deploy_artifact_paths(prefix, artifact_paths; strategy)
