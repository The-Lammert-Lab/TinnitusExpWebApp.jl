module TrialsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.ControllerHelper
using Combinatorics
using WAV: wavwrite
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieSession
using GenieAuthentication
using Genie.Exceptions
using InteractiveUtils: subtypes
using Base64
using JSON3
using SearchLight
using SearchLight.Validation
using SHA
using TinnitusReconstructor
using TinnitusReconstructor: Stimgen, BinnedStimgen

const IDEAL_BLOCK_SIZE = 8
const MAX_BLOCK_SIZE = 12

# Map of target sounds to their corresponding filenames
const TARGET_SOUND_MAP = Dict(
    "tea_kettle" => "media/audio/target_sounds/ATA_Tinnitus_Tea_Kettle_Tone_1sec.wav",
    "static" => "media/audio/target_sounds/ATA_Tinnitus_Static_Tone_1sec.wav",
    "screeching" => "media/audio/target_sounds/ATA_Tinnitus_Screeching_Tone_1sec.wav",
    "roaring" => "media/audio/target_sounds/ATA_Tinnitus_Roaring_Tone_1sec.wav",
    "electric" => "media/audio/target_sounds/ATA_Tinnitus_Electric_Tone_1sec.wav",
    "buzzing" => "media/audio/target_sounds/ATA_Tinnitus_Buzzing_Tone_1sec.wav"
)

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
    gen_b64_stimuli(s::SG, n_trials::I) where {SG<:BinnedStimgen,I<:Integer}
    gen_b64_stimuli(s::SG, n_trials::I) where {SG<:Stimgen,I<:Integer}

Generate a vector of `n_trials` base64 encoded stimuli from stimgen settings.
    Returns either binned_repr_matrix or spect_matrix if `s` is not a subtype of `BinnedStimgen`.
"""
function gen_b64_stimuli(s::SG, n_trials::I) where {SG<:BinnedStimgen,I<:Integer}
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

function gen_b64_stimuli(s::SG, n_trials::I) where {SG<:Stimgen,I<:Integer}
    stimuli_matrix, Fs, spect_matrix, _ = generate_stimuli_matrix(s, n_trials)

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

    return stimuli, spect_matrix
end

"""
    choose_n_trials(x::I) where {I<:Integer}

Returns number of trials to use for this "block" based on `IDEAL_BLOCK_SIZE` and `MAX_BLOCK_SIZE` where `x` is the number of remaining trials.
"""
choose_n_trials(x::I) where {I<:Integer} =
    return x <= MAX_BLOCK_SIZE ? x : oftype(x, IDEAL_BLOCK_SIZE)

"""
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:Symbol, W}
    gen_stim_and_block(parameters::Dict{S, W}) where {S<:AbstractString, W}

Returns base64 encoded stimuli and vector of `Trial` structs (a "block") based on `parameters`.
    Assumes `parameters` has: `:name`, and `:instance`.
"""
function gen_stim_and_block(parameters::Dict{S,W}) where {S<:Symbol,W}
    instance = parse(Int, getindex(parameters, :instance))

    # Get experiment info and create stimgen struct
    e = findone(Experiment; name=getindex(parameters, :name))
    stimgen = stimgen_from_json(e.stimgen_settings, e.stimgen_type)

    # Decide on n_trials using existing data
    current_trials = find(
        Trial;
        experiment_name=e.name,
        instance=instance,
        user_id=current_user_id(),
    )

    remaining_trials = e.n_trials - length(current_trials)
    n_trials = choose_n_trials(remaining_trials)

    if n_trials < 1
        return [], [], NaN
    end

    remaining_blocks = ceil(Int, remaining_trials / n_trials)

    # Get stimuli vector
    # Second output of gen_b64_stimuli is binned_repr_matrix or spect_matrix
    # if !(stimgen isa BinnedStimgen)
    stimuli, stim_rep_to_save = gen_b64_stimuli(stimgen, n_trials)

    # Make array of Trial structs
    block = [
        Trial(;
            stimulus=JSON3.write(stim),
            user_id=current_user_id(),
            experiment_name=e.name,
            instance=instance,
        ) for stim in eachcol(stim_rep_to_save)
    ]

    return stimuli, block, remaining_blocks
end

function gen_stim_and_block(parameters::Dict{S,W}) where {S<:AbstractString,W}
    instance = parse(Int, getindex(parameters, "instance"))

    # Get experiment info and create stimgen struct
    e = findone(Experiment; name=getindex(parameters, "name"))
    stimgen = stimgen_from_json(e.stimgen_settings, e.stimgen_type)

    # Decide on n_trials using existing data
    current_trials = find(
        Trial;
        experiment_name=e.name,
        instance=instance,
        user_id=current_user_id(),
    )

    remaining_trials = e.n_trials - length(current_trials)
    n_trials = choose_n_trials(remaining_trials)

    if n_trials < 1
        return [], [], NaN
    end

    remaining_blocks = ceil(Int, remaining_trials / n_trials)

    # Get stimuli vector
    # Second output of gen_b64_stimuli is binned_repr_matrix or spect_matrix
    # if !(stimgen isa BinnedStimgen)
    stimuli, stim_rep_to_save = gen_b64_stimuli(stimgen, n_trials)

    # Make array of Trial structs
    block = [
        Trial(;
            stimulus=JSON3.write(stim),
            user_id=current_user_id(),
            experiment_name=e.name,
            instance=instance,
        ) for stim in eachcol(stim_rep_to_save)
    ]

    return stimuli, block, remaining_blocks
end

#########################

## PAGE FUNCTIONS ##

#########################


function experiment()
    authenticated!()
    # Params = :name, :instance, :from

    # Validate that name refers to a real Experiment
    # Validaton of the trials is done during save.
    experiment = findone(Experiment; name=params(:name))
    if isnothing(experiment)
        return Router.error(
            INTERNAL_ERROR,
            """Experiment with name "$(params(:name))" could not be found""",
            MIME"application/json",
        )
    end

    GenieSession.set!(:n_trials, experiment.n_trials)
    if params(:from) == "rest"
        from_rest = true
        html(:trials, :experiment; from_rest)
    else
        from_rest = false
        stimuli, curr_block, remaining_blocks = gen_stim_and_block(params())

        if experiment.target_sound == ""
            # Non-Ax Experiment
            target_sound_path = ""
        else
            # Ax Experiment
            target_sound_path = TARGET_SOUND_MAP[experiment.target_sound]
        end

        if isempty(stimuli)
            throw(ExceptionalResponse(redirect("/profile")))
        else
            # Var for labelling audio elements
            counter = 0
            GenieSession.set!(:current_block, curr_block)

            html(:trials, :experiment; stimuli, counter, from_rest, remaining_blocks, target_sound_path)
        end
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
            error_info="Current block in session returned nothing.",
        )
    end

    curr_trial = popfirst!(curr_block)

    curr_usr_exp = findone(
        UserExperiment;
        experiment_name=curr_trial.experiment_name,
        instance=curr_trial.instance,
        user_id=current_user_id(),
    )

    n_trials = GenieSession.get!(:n_trials, nothing)
    if n_trials === nothing
        n_trials = findone(Experiment; name=curr_trial.experiment_name).n_trials
    end

    # Update
    curr_trial.response = jsonpayload("resp")
    curr_usr_exp.trials_complete += 1

    # Check if all trials are done
    exp_complete = curr_usr_exp.trials_complete >= n_trials ? true : false

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
    save(curr_usr_exp) && json(Dict(:exp_complete => (:value => exp_complete)))
end

function gen_stim_rest()
    authenticated!()
    stimuli, curr_block, _ = gen_stim_and_block(jsonpayload())
    if isempty(stimuli)
        Router.error(INTERNAL_ERROR, "No more trials to be done", MIME"application/json")
    else
        GenieSession.set!(:current_block, curr_block)
        json(stimuli)
    end
end

function done()
    authenticated!()
    html(:trials, :done)
end

end
