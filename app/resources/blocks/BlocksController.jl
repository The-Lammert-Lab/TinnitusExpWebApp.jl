module BlocksController

using CharacterizeTinnitus
using CharacterizeTinnitus.Blocks
using CharacterizeTinnitus.TinnitusReconstructor
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using WAV: wavwrite
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieSession
using GenieAuthentication
using InteractiveUtils: subtypes
using Base64
using JSON3
using SearchLight
using SHA

const STIMGEN_MAPPINGS = Dict{String,DataType}(
    "UniformPrior" => UniformPrior
)

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

"""
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:Symbol, W}
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:AbstractString, W}

Returns base64 encoded stimuli and Block struct based on `parameters`, which must come from `params()`.
    Assumes `parameters` has: `:name`, `:instance`, and `:from`.
"""
function gen_stim_and_block(parameters::Dict{S, W}) where {S<:Symbol, W}
    instance = parse(Int, getindex(parameters, :instance))

    # Get experiment info from Experiments table
    e = findone(Experiment; name = getindex(parameters, :name))
    stimgen = JSON3.read(e.stimgen_settings, STIMGEN_MAPPINGS[e.stimgen_type])

    # No blocks have been done, get n_blocks and n_trials_per_block from e
    if haskey(parameters, :from) && getindex(parameters, :from) == "start"
        n_blocks = e.n_blocks
        n_trials_per_block = e.n_trials_per_block
        curr_block_num = 1
    else
        # Get all existing blocks for this user's experiment and instance
        existing_blocks = find( Block; 
                                experiment_name = e.name, 
                                instance = instance,
                                user_id = current_user_id()
                            )
        curr_block_num = maximum(getproperty.(existing_blocks, :number)) + 1
        # Take from first in case there's only one. All should be the same.
        n_blocks = existing_blocks[1].n_blocks
        n_trials_per_block = existing_blocks[1].n_trials_per_block
    end

    # Get stimuli vector
    stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials_per_block)
    new_block = Block(;
                    stim_matrix = JSON3.write(binned_repr_matrix),
                    responses = "",
                    number = curr_block_num,
                    n_blocks = n_blocks,
                    n_trials_per_block = n_trials_per_block,
                    experiment_name = e.name,
                    user_id = current_user_id(),
                    instance = instance     
                )
                    
    return stimuli, new_block
end

function gen_stim_and_block(parameters::Dict{S, W}) where {S<:AbstractString, W}
    instance = parse(Int, getindex(parameters, "instance"))

    # Get experiment info from Experiments table
    e = findone(Experiment; name = getindex(parameters, "name"))
    stimgen = JSON3.read(e.stimgen_settings, STIMGEN_MAPPINGS[e.stimgen_type])

    # No blocks have been done, get n_blocks and n_trials_per_block from e
    if haskey(parameters, "from") && getindex(parameters, :from) == "start"
        n_blocks = e.n_blocks
        n_trials_per_block = e.n_trials_per_block
        curr_block_num = 1
    else
        # Get all existing blocks for this user's experiment and instance
        existing_blocks = find( Block; 
                                experiment_name = e.name, 
                                instance = instance,
                                user_id = current_user_id()
                            )
        curr_block_num = maximum(getproperty.(existing_blocks, :number)) + 1
        # Take from first in case there's only one. All should be the same.
        n_blocks = existing_blocks[1].n_blocks
        n_trials_per_block = existing_blocks[1].n_trials_per_block
    end

    # Get stimuli vector
    stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials_per_block)
    new_block = Block(;
                    stim_matrix = JSON3.write(binned_repr_matrix),
                    responses = "",
                    number = curr_block_num,
                    n_blocks = n_blocks,
                    n_trials_per_block = n_trials_per_block,
                    experiment_name = e.name,
                    user_id = current_user_id(),
                    instance = instance     
                )
                    
    return stimuli, new_block
end

#########################

## PAGE FUNCTIONS ##

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
    authenticated!()
    # Params = :name, :instance, :from
    if params(:from) == "rest"
        from_rest = true
        html(:blocks, :experiment; from_rest)
    else
        from_rest = false
        stimuli, curr_block = gen_stim_and_block(params())
        # Var for labelling audio elements
        counter = 0
        GenieSession.set!(:current_block, curr_block)
        html(:blocks, :experiment; stimuli, counter, from_rest)
    end
end

function rest()
    authenticated!()
    html(:blocks, :rest)
end

function save_responses()
    authenticated!()
    curr_block = GenieSession.get(:current_block, nothing)
    curr_exp = findone(UserExperiment; 
                        experiment_name = curr_block.experiment_name,
                        instance = curr_block.instance, 
                        user_id = current_user_id()
                    )
    if curr_block === nothing
        return Router.error(NOT_FOUND, "Block data not found", MIME"text/html")
    end
    # Update
    curr_block.responses = replace(jsonpayload("resps"))
    curr_exp.percent_complete = 100 * curr_block.number / curr_block.n_blocks

    # Save and send response
    save(curr_block) && save(curr_exp) && json(Dict(:number => (:value => curr_block.number), 
                                                    :n_blocks => (:value => curr_block.n_blocks)
                                            ))
end

function gen_stim_rest()
    authenticated!()
    stimuli, curr_block = gen_stim_and_block(jsonpayload())
    GenieSession.set!(:current_block, curr_block)
    json(stimuli)
end

function done()
    authenticated!()
    html(:blocks, :done)
end

end
