module BlocksController

# using Blocks
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.TinnitusReconstructor
using WAV: wavwrite
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using InteractiveUtils
using Base64
using JSON3
using SearchLight
using SHA

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


"""
    scale_audio(x)

Taken from MATLAB's `soundsc()`. Returns input scaled to between 1 and -1.
"""
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
    gen_b64_stimuli(s::SG, n_trials::I) where {SG<:Stimgen,I<:Integer}

Generate a vector of `n_trials` base64 encoded stimuli from stimgen settings.
"""
function gen_b64_stimuli(s::SG, n_trials::I) where {SG<:Stimgen,I<:Integer}
    stimuli_matrix, Fs, _, binned_repr_matrix = generate_stimuli_matrix(s, n_trials)

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

    return stimuli, binned_repr_matrix
end

#########################

## PAGE RENDERERS ##

#########################

function index()
    html(:blocks, :index)
end

function expsetup()
    # full_types is CharacterizeTinnitus.TinnitusReconstructor.XXXXX (typeof = Vector{DataType})
    full_types = _subtypes(Stimgen)

    # Get just the stimgen name
    # NOTE: This method can probably be considerably improved.
    stimgen_types = Vector{String}(undef, length(full_types))
    [stimgen_types[ind] = split.(type, '.')[end][end] for (ind, type) in enumerate(eachrow(string.(full_types)))]

    html(:blocks, :expsetup; stimgen_types)
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

        # Collect from parameters
        stimgen = eval(Meta.parse(params(:stimgen)))()
        n_trials_per_block = parse(Int, params(:n_trials_per_block))

        # Hash stimgen
        stimgen_json = JSON3.write(stimgen)
        stim_to_hash = string(string(params(:stimgen)), stimgen_json)
        stimgen_hash = bytes2hex(sha256(stim_to_hash))

        # Get stimuli vector
        stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials_per_block)

        B = Block(; 
            stim_matrix=JSON3.write(binned_repr_matrix),
            stimgen=stimgen_json, 
            stimgen_type=string(params(:stimgen)), 
            stimgen_hash=stimgen_hash,
            n_blocks=parse(Int, params(:n_blocks)), 
            n_trials_per_block=n_trials_per_block
        )

        save(B)

        # Var for labelling audio elements
        counter = 0

        html(:blocks, :experiment; stimuli, counter, from_rest)
    end
end

function rest()

    # Collect from parameters
    stimgen = eval(Meta.parse(params(:stimgen)))()
    n_trials_per_block = parse(Int, params(:n_trials_per_block))

    # Hash stimgen
    stimgen_json = JSON3.write(stimgen)
    stim_to_hash = string(string(params(:stimgen)), stimgen_json)
    stimgen_hash = bytes2hex(sha256(stim_to_hash))

    # Get stimuli vector
    stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials_per_block)

    B = Block(; 
        stim_matrix=JSON3.write(binned_repr_matrix),
        stimgen=stimgen_json, 
        stimgen_type=string(params(:stimgen)), 
        stimgen_hash=stimgen_hash,
        n_blocks=parse(Int, params(:n_blocks)), 
        n_trials_per_block=n_trials_per_block
    )

    save(B)

    counter = 0

    html(:blocks, :rest; stimuli, counter)
end

function done()
    html(:blocks, :done)
end

end
