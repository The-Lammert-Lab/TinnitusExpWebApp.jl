module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.Ratings
using CharacterizeTinnitus.ControllerHelper
using WAV: wavwrite
using Base64
using SearchLight
using SearchLight.Validation
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using Genie.Exceptions
using GenieSession
using TinnitusReconstructor
using TinnitusReconstructor: binnedrepr2wav, white_noise
using TinnitusReconstructor: pure_tone, gen_octaves
using DSP: Windows.tukey

"""
    ue2dict(UE::V) where {V <: Vector{CharacterizeTinnitus.UserExperiments.UserExperiment}}

Converts UserExperiments to dictionary with 
    username, instance, and percent_complete fields.
    Slightly different from `ue2dict` in ExperimentsController.
    Distinguished by the module, not the arguments. 
"""
function ue2dict(
    UE::V,
) where {V<:Vector{CharacterizeTinnitus.UserExperiments.UserExperiment}}
    ae_data = Vector{Dict{Symbol,Any}}(undef, length(UE))
    for (ind, ae) in enumerate(UE)
        exp = findone(Experiment; name=ae.experiment_name)
        n_trials = exp.n_trials
        threshold_determination_mode = exp.threshold_determination_mode
        loudness_matching = exp.loudness_matching
        pitch_matching = exp.pitch_matching

        status = if ae.trials_complete >= n_trials
            "completed"
        elseif ae.trials_complete > 0
            "started"
        else
            "unstarted"
        end

        # Add dictionary to user_data
        ae_data[ind] = Dict(
            :name => ae.experiment_name,
            :instance => ae.instance,
            :percent_complete => round(100 * ae.trials_complete / n_trials; digits=2),
            :status => status,
            :threshold_determination_mode => threshold_determination_mode,
            :loudness_matching => loudness_matching,
            :pitch_matching => pitch_matching,
            )
    end
    return ae_data
end

function restart_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")
    instance = jsonpayload("instance")
    user_id = findone(User; username=jsonpayload("username")).id

    # Check if there is another of same experiment with no trials done.
    existing_unstarted =
        find(UserExperiment; experiment_name=name, user_id=user_id, trials_complete=0)
    if !isempty(existing_unstarted)
        return Router.error(
            INTERNAL_ERROR,
            """Could not restart experiment "$(name)", instance "$(instance)". An unstarted instance of "$(name)" already exists for user "$(username(user_id))".""",
            MIME"application/json",
        )
    end

    experiment = findone(
        UserExperiment;
        experiment_name=name,
        instance=instance,
        user_id=user_id,
    )

    if experiment === nothing
        return Router.error(
            INTERNAL_ERROR,
            """Could not find an experiment with name "$(name)" and instance "$(instance)" for user "$(username(user_id))" to restart.""",
            MIME"application/json",
        )
    end

    trials = find(Trial; experiment_name=name, instance=instance, user_id=user_id)

    experiment.trials_complete = 0
    save(experiment) && SearchLight.delete.(trials)
    json(
        """Experiment "$(name)" instance $(instance) restarted for user "$(username(user_id))." """,
    )
end

function remove_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")
    instance = jsonpayload("instance")
    user_id = findone(User; username=jsonpayload("username")).id

    trials = find(Trial; experiment_name=name, instance=instance, user_id=user_id)

    if !isempty(trials)
        return Router.error(
            INTERNAL_ERROR,
            """Could not remove experiment "$(name)", instance "$(instance)". User "$(username(user_id))" has saved trials.""",
            MIME"application/json",
        )
    end

    ue = findone(
        UserExperiment;
        experiment_name=name,
        instance=instance,
        user_id=user_id,
    )

    if ue === nothing
        return Router.error(
            INTERNAL_ERROR,
            """Could not find an experiment with name "$(name)" and instance "$(instance)" for user "$(username(user_id))" to remove.""",
            MIME"application/json",
        )
    end

    SearchLight.delete(ue)
    json(
        """Experiment "$(name)" instance $(instance) removed from user "$(username(user_id))." """,
    )
end

function add_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("experiment")
    user_id = findone(User; username=jsonpayload("username")).id

    curr_user_exps = find(UserExperiment; experiment_name=name, user_id=user_id)

    # Check request validity (can't add experiment if unstarted already exists)
    if any(i -> i == 0, getproperty.(curr_user_exps, :trials_complete))
        return Router.error(
            INTERNAL_ERROR,
            """Could not add experiment "$(name)". An unstarted instance already exists.""",
            MIME"application/json",
        )
    end

    # Get instance of new experiment
    if !isempty(curr_user_exps)
        new_instance = maximum(getproperty.(curr_user_exps, :instance)) + 1
    else
        new_instance = 1
    end

    # Create
    ue = UserExperiment(;
        user_id=user_id,
        experiment_name=name,
        instance=new_instance,
        trials_complete=0,
    )

    # Validate
    validator = validate(ue)
    if haserrors(validator)
        return Router.error(
            INTERNAL_ERROR,
            errors_to_string(validator),
            MIME"application/json",
        )
    end

    save(ue) && json("""Experiment "$(name)" added to user "$(username(user_id))." """)
end

function get_partial_data()
    authenticated!()

    # Avoid errors if any payload params come in as a string
    limit =
        jsonpayload("limit") isa AbstractString ? parse(Int, jsonpayload("limit")) :
        jsonpayload("limit")
    page =
        jsonpayload("page") isa AbstractString ? parse(Int, jsonpayload("page")) :
        jsonpayload("page")

    if page < 1 || page === nothing
        page = 1
    end

    if limit < 1 || limit === nothing
        limit = 1
    end

    # If a specific username is given (called from /manage), use that.
    user_id = try
        findone(User; username=jsonpayload("username")).id
    catch
        current_user_id()
    end

    if jsonpayload("type") == "UserExperiment"
        added_experiments =
            get_paginated_amount(UserExperiment, limit, page; user_id=user_id)
        ae_data = ue2dict(added_experiments)
        return json(ae_data)
    else
        return Router.error(
            INTERNAL_ERROR,
            "Unrecognized request type",
            MIME"application/json",
        )
    end
end

# renders HTML page which sets mult and binrange for resynthesis per user per experiment
function adjust_resynth()
    authenticated!()

    curr_usr_exp = findone(
        UserExperiment;
        experiment_name=params(:name),
        instance=params(:instance),
        user_id=current_user_id(),
    )

    # get current mult and binrange values
    curr_mult = curr_usr_exp.mult
    curr_binrange = curr_usr_exp.binrange

    html(:userexperiments, :adjustResynth; curr_mult, curr_binrange)
end

"""
creates wav audios:
1) standard resynthesis
2) adjusted resynthesis
"""
function get_standard_and_adjusted_resynth(experiment_name, instance, user_id, mult, binrange)
    authenticated!()

    e = findone(Experiment; name=experiment_name)
    stimgen = stimgen_from_json(e.stimgen_settings, e.stimgen_type)

    all_trials = find(Trial; experiment_name=experiment_name, instance=instance, user_id=user_id)

    for (index, stimulus) in enumerate(all_trials)
        all_trials[index].stimulus = all_trials[index].stimulus[2:end-1]
    end

    responses = getproperty.(all_trials, :response)
    stimuli = [parse.(Float64, split(trial.stimulus, ",")) for trial in all_trials]

    recon = TinnitusReconstructor.gs(responses, stack(stimuli)')
    print(stimgen)
    print(recon)
    standard_resynth_wav = binnedrepr2wav(stimgen, recon, min_db=-15) .* 10 
    adjusted_resynth_wav, adjusted_resynth_spect = binnedrepr2wav(stimgen, recon, mult, binrange)
    
    # print(adjusted_resynth_wav)

    buf = Base.IOBuffer()
    wavwrite(adjusted_resynth_wav, buf; Fs=44100.0)
    adjusted_resynth_wav_base = base64encode(take!(buf))
    close(buf)

    buf = Base.IOBuffer()
    wavwrite(standard_resynth_wav, buf; Fs=44100.0)
    standard_resynth_wav_base = base64encode(take!(buf))
    close(buf)

    return adjusted_resynth_wav_base, standard_resynth_wav_base
end

"""
returns Adjusted wav audio
this is called through a javascript function to add adjusted_wab_file as the src to the audio tag
"""
function play_adjusted_audio()
    authenticated!()
    # Extract the mult and binrange values
    mult = parse(Float64, params(:JSON_PAYLOAD)["mult"])
    binrange = parse(Float64, params(:JSON_PAYLOAD)["binrange"])

    name = params(:name)
    instance = params(:instance)
    user_id = current_user_id()

    adjusted_wav_file, = get_standard_and_adjusted_resynth(name, instance, user_id, mult, binrange)

    return json(adjusted_wav_file)
end

"""
Saves the mult and binrange values per user per experiment in UserExperiment table.
This function is called when the user has pressed the 'Save' button on the adjustResynth.jl.html page.
"""
function save_mult_and_binrange()
    # Parse the mult and binrange values from the JSON payload
    mult = parse(Float64, params(:JSON_PAYLOAD)["mult"])
    binrange = parse(Float64, params(:JSON_PAYLOAD)["binrange"])

    # Find the UserExperiment with the specified experiment name, instance, and user id
    curr_usr_exp = findone(
        UserExperiment;
        experiment_name=params(:name),
        instance=params(:instance),
        user_id=current_user_id(),
    )

    # Update the mult and binrange values
    curr_usr_exp.mult = mult
    curr_usr_exp.binrange = binrange

    # Save the changes
    save(curr_usr_exp)
end

"""
returns wav audio of three sounds required for the likert questions task.
1) White noise
2) Adjusted resynthesized audio
3) Standard resynthesized audio
"""
function likert_questions()
    authenticated!()

    curr_usr_exp = findone(
        UserExperiment;
        experiment_name=params(:name),
        instance=params(:instance),
        user_id=current_user_id(),
    )

    # white noise
    white_noise_wav = white_noise(44100, 0.5)

    # standard resynth and adjustted resynth
    # matlab code
    # recon_binrep = rescale(reconstruction, -20, 0);
    # recon_spectrum = stimgen.binnedrepr2spect(recon_binrep);

    # % Create frequency vector 
    # freqs = linspace(1, floor(Fs/2), length(recon_spectrum))' - 1; 

    # recon_spectrum(freqs > config.max_freq | freqs < config.min_freq) = stimgen.unfilled_dB;
    # recon_waveform_standard = stimgen.synthesize_audio(recon_spectrum, stimgen.nfft);
    adjusted_resynth_wav, standard_resynth_wav = get_standard_and_adjusted_resynth(params(:name), params(:instance), current_user_id(), curr_usr_exp.mult, curr_usr_exp.binrange)

    buf = Base.IOBuffer()
    wavwrite(white_noise_wav, buf; Fs=44100.0)
    white_noise_wav = base64encode(take!(buf))
    close(buf)

    html(:userexperiments, :likertQuestions; white_noise_wav, standard_resynth_wav, adjusted_resynth_wav)

end



#########################

## PAGE FUNCTIONS ##

#########################

function profile()
    authenticated!()

    init_limit = 5
    init_page = 1
    max_btn_display = 4
    added_experiments = get_paginated_amount(
        UserExperiment,
        init_limit,
        init_page;
        user_id=current_user_id(),
    )

    num_aes =
        count(UserExperiment; user_id=current_user_id()) > 0 ?
        count(UserExperiment; user_id=current_user_id()) : 1

    max_btn = convert(Int, ceil(num_aes / init_limit))
    if max_btn <= max_btn_display
        user_ae_table_pages_btns = 1:max_btn
    else
        user_ae_table_pages_btns = [range(1, max_btn_display - 1)..., "...", max_btn]
    end

    ae_data = ue2dict(added_experiments)

    user = current_user()
    is_admin = user.is_admin
    username = user.username
    print("Added Exp")

    html(
        :userexperiments,
        :profile;
        added_experiments,
        is_admin,
        username,
        ae_data,
        num_aes,
        user_ae_table_pages_btns,
        init_limit,
        init_page,
    )
end

function calibrate()
    authenticated!()

    pure_tone_wav = pure_tone(1000, 1, 44100)

    buf = Base.IOBuffer()
    wavwrite(pure_tone_wav, buf; Fs=44100.0)
    pure_tone_wav = base64encode(take!(buf))
    close(buf)

    html(:userexperiments, :calibrate; pure_tone_wav)
end

function instructions()
    authenticated!()
    html(
        :userexperiments, :instructions;
    )
end

end
