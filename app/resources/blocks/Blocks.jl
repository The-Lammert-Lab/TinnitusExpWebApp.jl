module Blocks

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Block

@kwdef mutable struct Block{T,W} <: AbstractModel where {T<:Real,W<:Integer}
    id::DbId = DbId()
    stim_matrix::AbstractArray{T} = [1.0 2.0 3.0; 4.0 5.0 6.0]
    responses::AbstractVector{W} = [1, 2, 3, 4]
    n_blocks::W = 0
    n_trials_per_block::W = 0
    stimgen::String = "UniformPrior"
    min_freq::T = 100.0
    max_freq::T = 13e3
    duration::T = 0.5
    n_trials::W = 2000
    fs::T = 44100.0
    n_bins::W = 100
    min_bins::W = 20
    max_bins::W = 30
end

end
