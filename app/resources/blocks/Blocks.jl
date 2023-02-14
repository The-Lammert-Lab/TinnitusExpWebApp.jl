module Blocks

using CharacterizeTinnitus.TinnitusReconstructor
import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Block

# TODO: Figure out default values (should probably all be empty). 
# Write stimgen2blocks method.
@kwdef mutable struct Block <: AbstractModel
    id::DbId = DbId()
    stim_matrix::String = ""
    responses::String = ""
    n_blocks::Integer = 0
    n_trials_per_block::Integer = 0
    stimgen::String = "UniformPrior"
    min_freq::Real = 100.0
    max_freq::Real = 13e3
    duration::Real = 0.5
    n_trials::Integer = 0
    Fs::Real = 44100.0
    n_bins::Integer = 100
    min_bins::Integer = 20
    max_bins::Integer = 30
end

# function Block(s::SG; kwargs...) where {SG<:Stimgen}


# end

end
