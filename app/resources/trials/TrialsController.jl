module TrialsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.TinnitusReconstructor
using CharacterizeTinnitus.TinnitusReconstructor: Stimgen
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using Combinatorics
using WAV: wavwrite
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieSession
using GenieAuthentication
using InteractiveUtils: subtypes
using Base64
using JSON3
using Primes
using SearchLight
using SearchLight.Validation
using SHA
using StructTypes

const STIMGEN_MAPPINGS = Dict{String,DataType}(
    "UniformPrior" => UniformPrior,
    "GaussianPrior" => GaussianPrior,
    "Brimijoin" => Brimijoin,
    "Bernoulli" => Bernoulli,
    "BrimijoinGaussianSmoothed" => BrimijoinGaussianSmoothed,
    "GaussianNoise" => GaussianNoise,
    "UniformNoise" => UniformNoise,
    "GaussianNoiseNoBins" => GaussianNoiseNoBins,
    "UniformNoiseNoBins" => UniformNoiseNoBins,
    "UniformPriorWeightedSampling" => UniformPriorWeightedSampling,
    "PowerDistribution" => PowerDistribution,
)

StructTypes.StructType(::Type{UniformPrior}) = StructTypes.Struct()
StructTypes.StructType(::Type{GaussianPrior}) = StructTypes.Struct()
StructTypes.StructType(::Type{Brimijoin}) = StructTypes.Struct()
StructTypes.StructType(::Type{Bernoulli}) = StructTypes.Struct()
StructTypes.StructType(::Type{BrimijoinGaussianSmoothed}) = StructTypes.Struct()
StructTypes.StructType(::Type{GaussianNoise}) = StructTypes.Struct()
StructTypes.StructType(::Type{UniformNoise}) = StructTypes.Struct()
StructTypes.StructType(::Type{GaussianNoiseNoBins}) = StructTypes.Struct()
StructTypes.StructType(::Type{UniformNoiseNoBins}) = StructTypes.Struct()
StructTypes.StructType(::Type{UniformPriorWeightedSampling}) = StructTypes.Struct()
StructTypes.StructType(::Type{PowerDistribution}) = StructTypes.Struct()

const IDEAL_BLOCK_SIZE = 80
const MAX_BLOCK_SIZE = 120

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
    scaled_stimuli = mapslices(scale_audio, stimuli_matrix; dims = 1)

    # Save base64 encoded wav files to stimuli vector of strings
    stimuli = Vector{String}(undef, size(scaled_stimuli, 2))
    for (ind, stimulus) in enumerate(eachcol(scaled_stimuli))
        buf = Base.IOBuffer()
        wavwrite(stimulus, buf; Fs = Fs)
        stimuli[ind] = base64encode(take!(buf))
        close(buf)
    end

    return stimuli, binned_repr_matrix
end

"""
    choose_n_trials(x::I) where {I<:Integer}

Returns number of trials to use for this "block" based on `IDEAL_BLOCK_SIZE` and `MAX_BLOCK_SIZE`.
"""
function choose_n_trials(x::I) where {I<:Integer}
    if x <= MAX_BLOCK_SIZE
        return x
    elseif (x ÷ IDEAL_BLOCK_SIZE < 2) # Potential last block 
        n_trials = IDEAL_BLOCK_SIZE + (x % IDEAL_BLOCK_SIZE)
        if n_trials > MAX_BLOCK_SIZE # Large remainder, do in next block
            return IDEAL_BLOCK_SIZE
        else
            return n_trials
        end
    else
        return IDEAL_BLOCK_SIZE
    end
end


"""
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:Symbol, W}
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:AbstractString, W}

Returns base64 encoded stimuli and vector of `Trial` structs (a "block") based on `parameters`.
    Assumes `parameters` has: `:name`, and `:instance`.
"""
function gen_stim_and_block(parameters::Dict{S,W}) where {S<:Symbol,W}
    instance = parse(Int, getindex(parameters, :instance))

    # Get experiment info and create stimgen struct
    e = findone(Experiment; name = getindex(parameters, :name))
    stimgen = JSON3.read(e.stimgen_settings, STIMGEN_MAPPINGS[e.stimgen_type])

    # Decide on n_trials using existing data
    current_trials = find(
        Trial;
        experiment_name = e.name,
        instance = instance,
        user_id = current_user_id(),
    )

    remaining_trials = e.n_trials - length(current_trials)
    n_trials = choose_n_trials(remaining_trials)

    # Get stimuli vector
    stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials)

    # Make array of Trial structs
    block = [
        Trial(;
            stimulus = JSON3.write(stim),
            user_id = current_user_id(),
            experiment_name = e.name,
            instance = instance,
        ) for stim in eachcol(binned_repr_matrix)
    ]

    return stimuli, block
end

function gen_stim_and_block(parameters::Dict{S,W}) where {S<:AbstractString,W}
    instance = parse(Int, getindex(parameters, "instance"))

    # Get experiment info and create stimgen struct
    e = findone(Experiment; name = getindex(parameters, "name"))
    stimgen = JSON3.read(e.stimgen_settings, STIMGEN_MAPPINGS[e.stimgen_type])

    # Decide on n_trials using existing data
    current_trials = find(
        Trial;
        experiment_name = e.name,
        instance = instance,
        user_id = current_user_id(),
    )

    remaining_trials = e.n_trials - length(current_trials)
    n_trials = choose_n_trials(remaining_trials)

    # Get stimuli vector
    stimuli, binned_repr_matrix = gen_b64_stimuli(stimgen, n_trials)

    # Make array of Trial structs
    block = [
        Trial(;
            stimulus = JSON3.write(stim),
            user_id = current_user_id(),
            experiment_name = e.name,
            instance = instance,
        ) for stim in eachcol(binned_repr_matrix)
    ]

    return stimuli, block
end

#########################

## PAGE FUNCTIONS ##

#########################

function index()
    html(:trials, :index)
end

function experiment()
    authenticated!()
    # Params = :name, :instance, :from
    experiment = findone(Experiment; name = params(:name))
    GenieSession.set!(:n_trials, experiment.n_trials)
    if params(:from) == "rest"
        from_rest = true
        html(:trials, :experiment; from_rest)
    else
        from_rest = false
        stimuli, curr_block = gen_stim_and_block(params())
        # Var for labelling audio elements
        counter = 0
        GenieSession.set!(:current_block, curr_block)
        html(:trials, :experiment; stimuli, counter, from_rest)
    end
end

function rest()
    authenticated!()
    html(:trials, :rest)
end

function save_response()
    authenticated!()

    curr_block = GenieSession.get(:current_block, nothing)
    if curr_block === nothing
        return Router.error(
            INTERNAL_ERROR,
            "Could not save response.",
            MIME"application/json";
            error_info = "Current block in session returned nothing.",
        )
    end

    curr_trial = popfirst!(curr_block)

    curr_usr_exp = findone(
        UserExperiment;
        experiment_name = curr_trial.experiment_name,
        instance = curr_trial.instance,
        user_id = current_user_id(),
    )

    n_trials = GenieSession.get!(:n_trials, nothing)
    if n_trials === nothing
        n_trials = findone(Experiment; name = curr_trial.experiment_name).n_trials
    end
    new_frac_complete = ((curr_usr_exp.frac_complete * n_trials) + 1) / n_trials

    # Update
    curr_trial.response = jsonpayload("resp")
    curr_usr_exp.frac_complete = new_frac_complete

    # Validate before saving
    trial_validator = validate(curr_trial)
    usr_exp_validator = validate(curr_usr_exp)
    if haserrors(trial_validator)
        return Router.error(
            INTERNAL_ERROR,
            errors_to_string(trial_validator),
            MIME"application/json",
        )
    elseif haserrors(usr_exp_validator)
        return Router.error(
            INTERNAL_ERROR,
            errors_to_string(user_exp_validator),
            MIME"application/json",
        )
    end

    # Save to db and send response
    save(curr_trial) && GenieSession.set!(:curr_block, curr_block)
    save(curr_usr_exp) && json(Dict(:frac_complete => (:value => new_frac_complete)))
end

function gen_stim_rest()
    authenticated!()
    stimuli, curr_block = gen_stim_and_block(jsonpayload())
    GenieSession.set!(:current_block, curr_block)
    json(stimuli)
end

function done()
    authenticated!()
    html(:trials, :done)
end

end
