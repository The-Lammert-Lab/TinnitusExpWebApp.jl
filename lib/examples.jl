"""
Small example functions to do various operations.
    Mostly a reference file. 
"""

# using SearchLight
# using ..Main.UserApp.Experiments
# using ..Main.UserApp.UserExperiments
# using ..Main.UserApp.Users
# using ..Main.UserApp.TinnitusReconstructor
# using ..Main.UserApp.Blocks
# using JSON3
# using SHA

function get_stim_mat(id::I) where {I<:Integer}
    B = findone(Block, id=id)
    stim_mat = reshape(JSON3.read(B.stim_matrix), JSON3.read(B.stimgen).n_bins, B.n_trials_per_block)
    return stim_mat
end

# TODO: Find a way to avoid eval. 
function get_stimgen_struct(id::I) where {I<:Integer}
    block = findone(Block, id=id)
    stimgen = JSON3.read(block.stimgen, eval(Meta.parse(block.stimgen_type)))
    return stimgen
end

const STIMGEN_MAPPINGS = Dict{String,DataType}(
    "UniformPrior" => UniformPrior
)

"""
    stimgen_from_params(stimgen::S; kwargs...) where {S<:AbstractString}

Returns a stimgen struct with keyword arguments from stringified name.
"""
function stimgen_from_params(stimgen::S; kwargs...) where {S<:AbstractString}
    stimgen_args = "("
    for key in keys(kwargs)
        name = string(key)
        value = string(kwargs[key])
        if stimgen_args == "("
            stimgen_args = string(stimgen_args, name, "=", value)
        else
            stimgen_args = string(stimgen_args, ",", name, "=", value)
        end
    end
    stimgen_args = string(stimgen_args, ")")
    f = eval(Meta.parse(string("x ->", stimgen, stimgen_args)))
    return Base.invokelatest(f, ())
end

function reset_exp(name::S) where {S<:AbstractString}
    user = findone(User; username = "testuser")
    ue = findone(UserExperiment; experiment_name = name, user_id = user.id)
    ue.frac_complete = 0
    save(ue)
    blocks = find(Trial; experiment_name = name, user_id = user.id)
    delete.(blocks)
end
