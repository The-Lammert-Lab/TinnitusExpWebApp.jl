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


function index()
    # Errors even commented out inside index.jl.html so keeping here for reference
    # <% for_each(stimgen_types) do stimgen %>
    #     <option value="$(stimgen)">$(stimgen)</option>
    # <% end %> 

    html(:blocks, :index)
end

function exptest()
    # Assuming this is routed from expsetup

    # Create the block
    B = Block(; n_blocks=parse(Int, params(:n_blocks)), 
        n_trials_per_block=parse(Int, params(:n_trials_per_block))
    )

    # Turn relevant block params into stimgen
    s = block2stimgen(B)

    stimuli_matrix, Fs, _, _ = generate_stimuli_matrix(s)

    # Scale all columns
    scaled_stimuli = mapslices(scale_audio, stimuli_matrix; dims=1)

    # Save base64 encoded wav files to stimuli vector of strings
    stimuli = String[]
    for stimulus in eachcol(scaled_stimuli)
        buf = Base.IOBuffer()
        wavwrite(stimulus, buf; Fs=Fs)
        temp = base64encode(take!(buf))
        push!(stimuli, temp)
        close(buf)
    end

    # Vars for labelling audio and button elements
    counter_vec = collect(1:length(stimuli))
    counter = 0

    html(:blocks, :exptest; stimuli, counter, counter_vec)
end

function expsetup()
    html(:blocks, :expsetup)
end

function experiment()
    B = Block(; n_blocks = params(:n_blocks), n_trials_per_block = params(:n_trials_per_block))
    redirect("/exptest?Settings=$B")
end

end