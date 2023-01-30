using Pkg
using JLLPrefixes

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

prefix = get(ENV, "BUILDKITE_PLUGIN_JACK_PREFIX", "/usr/local")
install = extract_env_array("BUILDKITE_PLUGIN_JACK_INSTALL")
strategy = get(ENV, "BUILDKITE_PLUGIN_JACK_STRATEGY", "copy")

@assert strategy in ["copy", "symlink", "hardlink"] """
Invalid `strategy` specified. Valid values are `copy`, `symlink` and `hardlink`."""

println("--- Collecting Artifacts")
artifact_paths = collect_artifact_paths(install)

println("--- Deploying strategy for prefix")
if strategy === "copy"
    copy_artifact_paths(prefix, artifact_paths)
elseif strategy === "symlink"
    symlink_artifact_paths(prefix, artifact_paths)
elseif strategy === "hardlink"
    @error "Sorry, hardlink support is still making its way up the hill."
    # hardlink_artifact_paths(prefix, artifact_paths)
end
