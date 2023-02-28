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
    number::Integer
    user_id::DbId
    n_blocks::Integer
    n_trials_per_block::Integer
    experiment_name::String
    instance::Integer

    # Inner constructor for argument validation
    function Block(;
        id::DbId = DbId(),
        stim_matrix::S = "",
        responses::S = "",
        number::I = 1,
        n_blocks::I = 1,
        n_trials_per_block::I = 1,
        experiment_name::S = "",
        user_id::DbId = DbId(),
        instance::I = 1,
    ) where {I<:Integer,S<:AbstractString}
        @assert n_blocks > 0 "`n_blocks` must be greater than 0"
        @assert n_trials_per_block > 0 "`n_trials_per_block` must be greater than 0"
        @assert instance > 0 "`instance` must be greater than 0"

        return new(
            id,
            stim_matrix,
            responses,
            number,
            n_blocks,
            n_trials_per_block,
            experiment_name,
            user_id,
            instance
        )
    end
end

# TODO: Add n_blocks validation

end
