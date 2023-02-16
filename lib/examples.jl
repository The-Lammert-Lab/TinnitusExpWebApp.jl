"""
Small example functions to do various operations.
    Mostly a reference file. 
"""

using SearchLight
using CharacterizeTinnitus.Blocks
using JSON3

function get_stim_mat(id::I) where {I<:Integer}
    B = findone(Block, id=id)
    stim_mat = reshape(JSON3.read(B.stim_matrix), JSON3.read(B.stimgen).n_bins, B.n_trials_per_block)
    return stim_mat
end