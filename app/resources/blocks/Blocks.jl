module Blocks

using CharacterizeTinnitus.TinnitusReconstructor
using NamedTupleTools: ntfromstruct
import SearchLight: AbstractModel, DbId

export Block

mutable struct Block <: AbstractModel
    id::DbId
    stim_matrix::String
    responses::String
    n_blocks::Integer
    n_trials_per_block::Integer
    stimgen::String
    min_freq::AbstractFloat
    max_freq::AbstractFloat
    duration::AbstractFloat
    n_trials::Integer
    Fs::AbstractFloat
    n_bins::Integer
    min_bins::Integer
    max_bins::Integer

    # Inner constructor for argument validation and n_trials definition.
    function Block(
        id::DbId,
        stim_matrix::String,
        responses::String,
        n_blocks::Integer,
        n_trials_per_block::Integer,
        stimgen::String,
        min_freq::AbstractFloat,
        max_freq::AbstractFloat,
        duration::AbstractFloat,
        Fs::AbstractFloat,
        n_bins::Integer,
        min_bins::Integer,
        max_bins::Integer,
    )
        @assert n_blocks > 0 "`n_blocks` must be specified and greater than 0"
        @assert n_trials_per_block > 0 "`n_trials_per_block` must be specified and greater than 0"
        n_trials = n_blocks * n_trials_per_block

        return new(
            id,
            stim_matrix,
            responses,
            n_blocks,
            n_trials_per_block,
            stimgen,
            min_freq,
            max_freq,
            duration,
            n_trials,
            Fs,
            n_bins,
            min_bins,
            max_bins,
        )
    end
end


"""
    Block(; kwargs...)
    Block(s::SG; kwargs...) where {SG<:Stimgen}

Outer constructor for Block struct.
    If a subtype of TinnitusReconstructor.Stimgen is passed, 
    its fields are incorporated into the Block struct that is generated.
    `n_blocks` and `n_trials_per_block` are required kwargs.

# Keywords

- `id::DbId = DbId()`: Unique Id for the database entry.
- `stim_matrix::String = ""`: JSON matrix containing stimuli in columns.
- `responses::String = ""`: JSON vector containing responses to stimuli.
- `n_blocks::Integer = 0`: **REQUIRED** Number of blocks the subject will complete.
- `n_trials_per_block::Integer = 0`: **REQUIRED** Number of trials per block that the subject will complete.
----- **STIMGEN FIELDS** -----
- `stimgen::String = ""`: Name of stimgen type (stimgen struct from TinnitusReconstructor).
- `min_freq::Real = 0`: The minimum frequency in range from which to sample.
- `max_freq::Real = 0`: The maximum frequency in range from which to sample.
- `duration::Real = 0`: The length of time for which stimuli are played in seconds.
- `Fs::Real = 0`: The frequency of the stimuli in Hz.
- `n_bins::Integer = 0`: The number of bins into which to partition the frequency range.
- `min_bins::Integer = 0`: The minimum number of bins that may be filled on any stimuli.
- `max_bins::Integer = 0`: The maximum number of bins that may be filled on any stimuli.

# Additional fields
- `n_trials::Integer = n_blocks * n_trials_per_block`: Total number of trials to be completed.
        Not a valid input. The value will be inferred from `n_blocks` and `n_trials_per_block`. 
"""
function Block(;
    id::DbId = DbId(),
    stim_matrix::String = "",
    responses::String = "",
    n_blocks::Integer = 0,
    n_trials_per_block::Integer = 0,
    stimgen::String = "",
    min_freq::Real = 0,
    max_freq::Real = 0,
    duration::Real = 0,
    Fs::Real = 0,
    n_bins::Integer = 0,
    min_bins::Integer = 0,
    max_bins::Integer = 0,
)

    return Block(
        id,
        stim_matrix,
        responses,
        n_blocks,
        n_trials_per_block,
        stimgen,
        min_freq,
        max_freq,
        duration,
        Fs,
        n_bins,
        min_bins,
        max_bins,
    )
end

function Block(s::SG; kwargs...) where {SG<:Stimgen}
    # typeof(s) returns CharacterizeTinnitus.TinnitusReconstructor.XXXXX
    return Block(; stimgen = string(split.(string(typeof(s)), '.')[end]), ntfromstruct(s)..., kwargs...)
end

end
