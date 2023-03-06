"""
Small example functions to do various operations.
    Mostly a reference file. 
"""

using SearchLight
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.TinnitusReconstructor
using JSON3
using SHA

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

function reset_exp(name::S) where {S<:AbstractString}
    user = findone(User; username = "testuser")
    ue = findone(UserExperiment; experiment_name = name, user_id = user.id)
    ue.percent_complete = 0
    save(ue)
    blocks = find(Block; experiment_name = name, user_id = user.id)
    delete.(blocks)
end
