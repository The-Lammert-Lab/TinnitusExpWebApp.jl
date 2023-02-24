module Blocks

import SearchLight: AbstractModel, DbId

export Block

"""
    Block(; kwargs...)

Struct that holds information about the current experiment block.

# Fields

- `id::DbId = DbId()`: Unique Id for the database entry.
- `stim_matrix::String = ""`: JSON string containing stimuli.
- `responses::String = ""`: JSON vector containing responses to stimuli.
- `n_blocks::Integer = 0`: **REQUIRED** Number of blocks the subject will complete.
- `n_trials_per_block::Integer = 0`: **REQUIRED** Number of trials per block that the subject will complete.
- `n_trials::Integer = n_blocks * n_trials_per_block`: Total number of trials to be completed.
        **Not a valid input.** The value will be inferred from `n_blocks` and `n_trials_per_block`. 
- `stimgen::String = ""`: JSON string containing stimgen struct.
- `stimgen_type::String = ""`: Name of the stimgen type.
"""
mutable struct Block <: AbstractModel
    id::DbId
    stim_matrix::String
    responses::String
    n_blocks::Integer
    n_trials_per_block::Integer
    n_trials::Integer
    stimgen::String
    stimgen_type::String
    stimgen_hash::String

    # Inner constructor for argument validation, n_trials definition, and defaults.
    # TODO: Complete assertions.
    function Block(;
        id::DbId = DbId(),
        stim_matrix::S = "",
        responses::S = "",
        n_blocks::I = 1,
        n_trials_per_block::I = 1,
        stimgen::S = "",
        stimgen_type::S = "",
        stimgen_hash::S = "",
    ) where {I<:Integer,S<:AbstractString}
        @assert n_blocks > 0 "`n_blocks` must be greater than 0"
        @assert n_trials_per_block > 0 "`n_trials_per_block` must be greater than 0"
        n_trials = n_blocks * n_trials_per_block

        return new(
            id,
            stim_matrix,
            responses,
            n_blocks,
            n_trials_per_block,
            n_trials,
            stimgen,
            stimgen_type,
            stimgen_hash
        )
    end
end

end
