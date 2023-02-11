module BlocksController

# using Blocks
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.TinnitusReconstructor
using WAV: wavwrite
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using InteractiveUtils
using Base64

"""
  block2stimgen(B::Block)

Returns a stimgen type with settings from Block.
"""
function block2stimgen(B::Block)
    if B.n_blocks == 0 || B.n_trials_per_block == 0 
        n_trials = B.n_trials
    else
        n_trials = B.n_blocks*B.n_trials_per_block
    end

    stimgen = eval(Meta.parse(B.stimgen))(;
        min_freq=B.min_freq,
        max_freq=B.max_freq,
        duration=B.duration,
        n_trials=n_trials,
        Fs=B.fs,
        n_bins=B.n_bins,
        min_bins=B.min_bins,
        max_bins=B.max_bins
    )

    return stimgen
end

"""
    _subtypes(type::Type)    

Collect all concrete subtypes. 

# References
- https://gist.github.com/Datseris/1b1aa1287041cab1b2dff306ddc4f899
"""
function _subtypes(type::Type)
    out = Any[]
    _subtypes!(out, type)
end

function _subtypes!(out, type::Type)
    if !isabstracttype(type)
        push!(out, type)
    else
        foreach(T->_subtypes!(out, T), subtypes(type))
    end
    return out
end

function scale_audio(x)
    xmax = @. $maximum(abs, x[!isinf(x)])

    slim = [-xmax, xmax]

    dx = diff(slim)
    if iszero(dx)
        # Protect against divide-by-zero errors:
        x = zeros(size(x))
    else
        x = @. (x - slim[1]) / dx * 2 - 1
    end

    return x
end

"""
    gen_b64_stimuli(B::Block)

Generate a vector of base64 encoded stimuli from Block settings.
"""
function gen_b64_stimuli(B::Block)
    # Turn relevant block params into stimgen
    s = block2stimgen(B)

    stimuli_matrix, Fs, _, _ = generate_stimuli_matrix(s, B.n_trials_per_block)

    # Scale all columns
    scaled_stimuli = mapslices(scale_audio, stimuli_matrix; dims=1)

    # Save base64 encoded wav files to stimuli vector of strings
    stimuli = Vector{String}(undef, size(scaled_stimuli, 2))
    for (ind, stimulus) in enumerate(eachcol(scaled_stimuli))
        buf = Base.IOBuffer()
        wavwrite(stimulus, buf; Fs=Fs)
        stimuli[ind] = base64encode(take!(buf))
        close(buf)
    end

    return stimuli
end


function index()
    html(:blocks, :index)
end

function expsetup()
    html(:blocks, :expsetup)
end

function experiment()
    # This might not be necessary. Redirect is done in experiment.jl.html
    if params(:blocks_completed) == params(:n_blocks)
        redirect("/done")
    end

    if parse(Int, params(:blocks_completed)) > 0
        # Flag for if page is loaded mid-experiment (coming from rest page)
        from_rest = true
        html(:blocks, :experiment; from_rest)
    else
        from_rest = false

        # Create the block
        B = Block(; n_blocks=parse(Int, params(:n_blocks)), 
            n_trials_per_block=parse(Int, params(:n_trials_per_block))
        )

        # Get stimuli vector
        stimuli = gen_b64_stimuli(B)

        # Var for labelling audio elements
        counter = 0

        html(:blocks, :experiment; stimuli, counter, from_rest)
    end
end

function done()
    html(:blocks, :done)
end

function rest()
    # Create a new Block struct for the new block section
    B = Block(; n_blocks=parse(Int, params(:n_blocks)), 
    n_trials_per_block=parse(Int, params(:n_trials_per_block))
    )

    stimuli = gen_b64_stimuli(B)
    counter = 0

    html(:blocks, :rest; stimuli, counter)
end

end
