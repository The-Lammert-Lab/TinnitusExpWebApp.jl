module ExperimentsController

using CharacterizeTinnitus
using TinnitusReconstructor
using TinnitusReconstructor: Stimgen
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.ControllerHelper
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using Genie.Exceptions
using GenieAuthentication
using GenieSession
using InteractiveUtils: subtypes
using SearchLight
using SearchLight.Validation
using JSON3
using OrderedCollections

"""
    const EXPERIMENT_FIELDS = Dict{Symbol,String}

Maps stimgen fields to natural language descriptions.
"""
const EXPERIMENT_FIELDS = Dict{Symbol,String}(
    :min_freq => "Minimum frequency (Hz)",
    :max_freq => "Maximum frequency (Hz)",
    :duration => "Duration (s)",
    :n_bins => "Number of bins",
    :min_bins => "Minimum number of bins",
    :max_bins => "Maximum number of bins",
    :Fs => "Playback frequency (Hz)",
    :stimgen_type => "Stimgen type",
    :n_trials => "Number of trials",
    :name => "Experiment name",
    :target_sound => "Target sound",
    :n_bins_filled_mean => "Mean of Gaussian for filled bins",
    :n_bins_filled_var => "Variance of Gaussian for filled bins",
    :bin_prob => "Probability of a bin being filles",
    :amp_min => "Minimum amplitude of a bin (dB)",
    :amp_max => "Maximum amplitude of a bin (dB)",
    :amp_step => "Number of steps between min and max amplitude",
    :amplitude_mean => "Mean of Gaussian for amplitude (dB)",
    :amplitude_var => "Variance of Gaussian for amplitude (dB)",
    :alpha_ => "Exponential factor of number of unique frequencies in each bin",
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
        foreach(T -> _subtypes!(out, T), subtypes(type))
    end
    return out
end

"""
    ue2dict(UE::V) where {V <: Vector{CharacterizeTinnitus.UserExperiments.UserExperiment}}

Converts UserExperiments to dictionary with 
    username, instance, and percent_complete fields.
"""
function ue2dict(
    UE::V,
) where {V<:Vector{CharacterizeTinnitus.UserExperiments.UserExperiment}}
    user_data = Vector{Dict{Symbol,Any}}(undef, length(UE))
    cache = Dict{DbId,String}()
    for (ind, ae) in enumerate(UE)
        # Simple memoization 
        if ae.user_id in keys(cache)
            username = cache[ae.user_id]
        else
            username = findone(User; id=ae.user_id).username
            cache[ae.user_id] = username
        end

        n_trials = findone(Experiment; name=ae.experiment_name).n_trials

        # Add dictionary to user_data
        user_data[ind] = Dict(
            :username => username,
            :instance => ae.instance,
            :percent_complete => round(100 * ae.trials_complete / n_trials; digits=2),
        )
    end
    return user_data
end

"""
    view_exp()

Returns JSON response of requested experiment's fields and status for all users.
    
    Response is dictionary containing:

    - :experiment_data => :value, which holds a dictionary of the requested stimgen's 
    parameters in natural language form, excluding :id and :settings_hash.

    - :user_data => :value, which holds a vector of dictionaries, each containing
    username, instance, and trials_complete for every UserExperiment with requested experiment.
"""
function view_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")
    limit =
        jsonpayload("limit") isa AbstractString ? parse(Int, jsonpayload("limit")) :
        jsonpayload("limit")
    page =
        jsonpayload("page") isa AbstractString ? parse(Int, jsonpayload("page")) :
        jsonpayload("page")

    experiment = findone(Experiment; name=name)

    if experiment === nothing
        return Router.error(
            INTERNAL_ERROR,
            """Could not find an experiment with name "$(name)".""",
            MIME"application/json",
        )
    end

    # Get all user experiments for this experiment
    added_experiments =
        get_paginated_amount(UserExperiment, limit, page; experiment_name=name)
    user_data = ue2dict(added_experiments)

    # Can't initialize length b/c varying stimgen_settings fields
    # Making exp_data a OrderedDict, to keep "Experiement Name" field at the top.
    exp_data = OrderedDict{String,Any}(EXPERIMENT_FIELDS[:name] => name)
    skip_fields = [:id, :settings_hash]
    skip_settings = [:bin_probs, :distribution, :distribution_filepath]

    experiment_fields = fieldnames(typeof(experiment))

    for field in experiment_fields
        if field in skip_fields || field == :name
            continue
        elseif field == :stimgen_settings
            # Loop over :stimgen_settings field, which is JSON of stimgen.
            settings = JSON3.read(getproperty(experiment, field))
            for setting in keys(settings)
                if setting in skip_settings
                    continue
                elseif setting in keys(EXPERIMENT_FIELDS)
                    exp_data[EXPERIMENT_FIELDS[setting]] = getproperty(settings, setting)
                else # Do not skip field if no natural language version written.
                    exp_data[setting] = getproperty(settings, setting)
                end
            end
        else
            if field in keys(EXPERIMENT_FIELDS)
                if isempty(getproperty(experiment, field))
                    exp_data[EXPERIMENT_FIELDS[field]] = "N/A"
                else
                    exp_data[EXPERIMENT_FIELDS[field]] = getproperty(experiment, field)
                end
            else # Do not skip field if no natural language version written.
                exp_data[field] = getproperty(experiment, field)
            end
        end
    end

    max_data =
        count(UserExperiment; experiment_name=name) > 0 ?
        count(UserExperiment; experiment_name=name) : 1

    return json(
        Dict(
            :experiment_data => (:value => exp_data),
            :user_data => (:value => user_data),
            :max_data => (:value => max_data),
        ),
    )
end

"""
    get_exp_fields()
    get_exp_fields(ex::E) where {E<:Experiment}

Returns Vector{NamedTuple} corresponding to each non-stimgen field in a generic or specific experiment (`ex`).
    Each NamedTuple has `name`, `label`, `type`, and `value`.
"""
function get_exp_fields()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    ex = Experiment()
    fnames = fieldnames(typeof(ex))
    exclude = [
        :id,
        :stimgen_settings,
        :stimgen_type,
        :settings_hash,
        :bin_probs,
        :distribution,
        :distribution_filepath,
        :target_sound,
    ]

    exp_inds = findall(!in(exclude), fnames)

    exp_fields = Vector{NamedTuple}(undef, length(exp_inds))
    for (ind, field) in enumerate(fnames[exp_inds])
        fieldtype = typeof(getproperty(ex, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        else
            input_type = "text"
        end

        lab = field in keys(EXPERIMENT_FIELDS) ? EXPERIMENT_FIELDS[field] : field

        exp_fields[ind] =
            (name=field, label=lab, type=input_type, value="", step=step)
    end

    return exp_fields
end

function get_exp_fields(ex::E) where {E<:Experiment}
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    fnames = fieldnames(typeof(ex))
    exclude = [
        :id,
        :stimgen_settings,
        :stimgen_type,
        :settings_hash,
        :bin_probs,
        :distribution,
        :distribution_filepath,
        :target_sound,
    ]

    exp_inds = findall(!in(exclude), fnames)

    exp_fields = Vector{NamedTuple}(undef, length(exp_inds))
    for (ind, field) in enumerate(fnames[exp_inds])
        fieldtype = typeof(getproperty(ex, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        else
            input_type = "text"
        end

        lab = field in keys(EXPERIMENT_FIELDS) ? EXPERIMENT_FIELDS[field] : field

        exp_fields[ind] = (
            name=field,
            label=lab,
            type=input_type,
            value=getproperty(ex, field),
            step=step,
        )
    end

    return exp_fields
end

"""
    get_stimgen_fields(s::SG) where {SG<:Stimgen}

Returns Vector{NamedTuple} corresponding to each field in the stimgen struct `s`.
    Each NamedTuple has `name`, `label`, `type`, and `value`.
"""
function get_stimgen_fields(s::SG) where {SG<:Stimgen}
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    fnames = fieldnames(typeof(s))
    exclude = [:bin_probs, :distribution, :distribution_filepath]
    sg_inds = findall(!in(exclude), fnames)

    sg_fields = Vector{NamedTuple}(undef, length(fnames[sg_inds]))
    for (ind, field) in enumerate(fnames[sg_inds])
        fieldtype = typeof(getproperty(s, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        else
            input_type = "text"
        end

        lab = field in keys(EXPERIMENT_FIELDS) ? EXPERIMENT_FIELDS[field] : field

        sg_fields[ind] = (
            name=field,
            label=lab,
            type=input_type,
            value=getproperty(s, field),
            step=step,
        )
    end
    return sg_fields
end

function get_partial_data()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

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

    if jsonpayload("type") == "User"
        users = get_paginated_amount(User, limit, page; is_admin=false)
        return json(getproperty.(users, :username))
    elseif jsonpayload("type") == "UserExperiment"
        users_with_curr_exp = get_paginated_amount(
            UserExperiment,
            limit,
            page;
            experiment_name=jsonpayload("name"),
        )
        user_data = ue2dict(users_with_curr_exp)

        max_data =
            count(UserExperiment; experiment_name=jsonpayload("name")) > 0 ?
            count(UserExperiment; experiment_name=jsonpayload("name")) : 1

        return json(
            Dict(:user_data => (:value => user_data), :max_data => (:value => max_data)),
        )
    end
end

#########################

## PAGE FUNCTIONS ##

#########################

function admin()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    init_limit = 2
    init_page = 1
    max_btn_display = 4

    experiment_names = getproperty.(all(Experiment), :name)
    users = get_paginated_amount(User, init_limit, init_page; is_admin=false)
    num_users = count(User; is_admin=false) > 0 ? count(User; is_admin=false) : 1

    max_btn = convert(Int, ceil(num_users / init_limit))
    if max_btn <= max_btn_display
        user_table_pages_btns = 1:max_btn
    else
        user_table_pages_btns = [range(1, max_btn_display - 1)..., "...", max_btn]
    end

    html(
        :experiments,
        :admin;
        users,
        experiment_names,
        user_table_pages_btns,
        num_users,
        init_limit,
        init_page,
    )
end

function create()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    full_types = _subtypes(Stimgen)

    stimgen_types = last.(split.(string.(full_types), '.'))

    # From template experiment or not
    if haskey(params(), :template) && !isempty(params(:template))
        ex = findone(Experiment; name=params(:template))
        if ex === nothing
            return redirect("/create")
        end
        type = ex.stimgen_type
        stimgen = stimgen_from_json(ex.stimgen_settings, type)
        exp_fields = get_exp_fields(ex)
        stimgen_fields = get_stimgen_fields(stimgen)
    else
        exp_fields = get_exp_fields()
        stimgen_fields = nothing
        type = nothing
    end

    html(:experiments, :create; stimgen_types, exp_fields, stimgen_fields, type)
end

function get_stimgen()
    s = STIMGEN_MAPPINGS[params(:type)]()
    stimgen_fields = get_stimgen_fields(s)

    json(stimgen_fields)
end

function save_exp()
    exp_data = JSON3.read(jsonpayload("experiment"))
    sg_data = jsonpayload("stimgen")
    sg_type = jsonpayload("stimgen_type")

    ex = Experiment(; stimgen_settings=sg_data, stimgen_type=sg_type)

    # Add fields to experiment.
    for field in eachindex(exp_data)
        val = tryparse(Float64, exp_data[field])
        if val === nothing
            val = exp_data[field]
        end
        setproperty!(ex, Symbol(field), val)
    end

    # Make sure experiment is valid before other checks.
    validator = validate(ex)
    if haserrors(validator)
        return Router.error(
            BAD_REQUEST,
            """Invalid settings: "$(errors_to_string(validator))".""",
            MIME"application/json",
        )
    end

    # Check for identical experiments
    identical_exp = findone(
        Experiment;
        settings_hash=ex.settings_hash,
        stimgen_type=sg_type,
        n_trials=ex.n_trials,
    )

    if identical_exp !== nothing
        return Router.error(
            INTERNAL_ERROR,
            """An experiment with these exact settings already exists as: "$(identical_exp.name)".""",
            MIME"application/json",
        )
    end

    # Check that ex.n_trials is not within ± `pm` n_trials of existing, otherwise identical experiments.
    same_sg_exps =
        find(Experiment; settings_hash=ex.settings_hash, stimgen_type=sg_type)

    pm = 100
    for val in getproperty.(same_sg_exps, :n_trials)
        if val - pm <= ex.n_trials <= val + pm
            return Router.error(
                INTERNAL_ERROR,
                """At least one experiment with these settings within +/- $(pm) trials exists. Please pick a different number of trials.""",
                MIME"application/json",
            )
        end
    end

    save(ex) && json("""Experiment "$(ex.name)" successfully saved.""")
end

function delete_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")

    ex = findone(Experiment; name=name)
    if ex === nothing
        return Router.error(
            BAD_REQUEST,
            """Could not find an experiment with name "$(name)" to delete.""",
            MIME"application/json",
        )
    end

    added_ues = find(UserExperiment; experiment_name=name)
    if !isempty(added_ues)
        return Router.error(
            INTERNAL_ERROR,
            """Experiment "$(name)" is added to user(s): $(unique(username.(getproperty.(added_ues, :user_id)))). Cannot delete.""",
            MIME"application/json",
        )
    end

    SearchLight.delete(ex)
    json("""Experiment "$(name)" deleted.""")
end

end
