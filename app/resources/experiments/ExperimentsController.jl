module ExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.TinnitusReconstructor
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Experiments
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using Genie.Exceptions
using GenieAuthentication
using GenieSession
using InteractiveUtils: subtypes
using NamedTupleTools
using SearchLight
using SearchLight.Validation
using JSON3
using StructTypes


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
    :visible => "Visible",
)


"""
    const STIMGEN_MAPPINGS = Dict{String,DataType}

Maps stimgen name as string to DataType
"""
const STIMGEN_MAPPINGS =
    Dict{String,DataType}("UniformPrior" => UniformPrior, "GaussianPrior" => GaussianPrior)

# Register stimgens with StructTypes.
StructTypes.StructType(::Type{UniformPrior}) = StructTypes.Struct()
StructTypes.StructType(::Type{GaussianPrior}) = StructTypes.Struct()

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
    view_exp()

Returns JSON response of requested experiment's fields and status for all users.
    
    Response is dictionary containing:

    - :experiment_data => :value, which holds a dictionary of the requested stimgen's 
    parameters in natural language form, excluding :id and :settings_hash.

    - :user_data => :value, which holds a vector of dictionaries, each containing
    username, instance, and frac_complete for every UserExperiment with requested experiment.
"""
function view_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    ex = findone(Experiment; name = params(:name))
    if ex === nothing
        return Router.error(
            INTERNAL_ERROR,
            """Could not find an experiment with name "$(params(:name))".""",
            MIME"application/json",
        )
    end

    # Get all user experiments for this experiment
    added_experiments = find(UserExperiment; experiment_name = params(:name))

    # Make a vector of dicts with data to display
    user_data = Vector{Dict{Symbol,Any}}(undef, length(added_experiments))
    cache = Dict{DbId,String}()
    for (ind, ae) in enumerate(added_experiments)
        # Simple memoization 
        if ae.user_id in keys(cache)
            username = cache[ae.user_id]
        else
            username = findone(User; id = ae.user_id).username
            cache[ae.user_id] = username
        end

        # Add dictionary to user_data
        user_data[ind] = Dict(
            :username => username,
            :instance => ae.instance,
            :frac_complete => ae.frac_complete,
        )
    end

    # Pre-process experiment fields
    exp_data = Dict() # Can't initialize length b/c varying stimgen_settings fields
    skip_fields = [:id, :settings_hash]
    for field in fieldnames(typeof(ex))
        if field in skip_fields
            continue
        elseif field == :stimgen_settings
            # Loop over :stimgen_settings field, which is JSON of stimgen.
            settings = JSON3.read(getproperty(ex, field))
            for setting in keys(settings)
                if setting in keys(EXPERIMENT_FIELDS)
                    exp_data[EXPERIMENT_FIELDS[setting]] = getproperty(settings, setting)
                else # Do not skip field if no natural language version written.
                    exp_data[setting] = getproperty(settings, setting)
                end
            end
        else
            if field in keys(EXPERIMENT_FIELDS)
                exp_data[EXPERIMENT_FIELDS[field]] = getproperty(ex, field)
            else # Do not skip field if no natural language version written.
                exp_data[field] = getproperty(ex, field)
            end
        end
    end

    return json(
        Dict(:experiment_data => (:value => exp_data), :user_data => (:value => user_data)),
    )
end

"""
    get_exp_fields()
    get_exp_fields(ex::E) where {E<:Experiment}

Returns Vector{NamedTuple} corresponding to each non-stimgen field in a generic or specific experiment.
    Each NamedTuple has `name`, `label`, `type`, and `value`.
"""
function get_exp_fields()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    ex = Experiment()
    fnames = fieldnames(typeof(ex))
    exclude = [:id, :stimgen_settings, :stimgen_type, :settings_hash]

    exp_inds = findall(!in(exclude), fnames)

    exp_fields = Vector{NamedTuple}(undef, length(exp_inds))
    for (ind, field) in enumerate(fnames[exp_inds])
        fieldtype = typeof(getproperty(ex, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        elseif fieldtype <: AbstractString
            input_type = "text"
        else
            input_type = "text"
        end

        if field in keys(EXPERIMENT_FIELDS)
            lab = EXPERIMENT_FIELDS[field]
        else
            lab = field
        end

        exp_fields[ind] =
            (name = field, label = lab, type = input_type, value = "", step = step)
    end

    return exp_fields
end

function get_exp_fields(ex::E) where {E<:Experiment}
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    fnames = fieldnames(typeof(ex))
    exclude = [:id, :stimgen_settings, :stimgen_type, :settings_hash]

    exp_inds = findall(!in(exclude), fnames)

    exp_fields = Vector{NamedTuple}(undef, length(exp_inds))
    for (ind, field) in enumerate(fnames[exp_inds])
        fieldtype = typeof(getproperty(ex, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        elseif fieldtype <: AbstractString
            input_type = "text"
        else
            input_type = "text"
        end

        if field in keys(EXPERIMENT_FIELDS)
            lab = EXPERIMENT_FIELDS[field]
        else
            lab = field
        end

        exp_fields[ind] = (
            name = field,
            label = lab,
            type = input_type,
            value = getproperty(ex, field),
            step = step,
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
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    fnames = fieldnames(typeof(s))

    sg_fields = Vector{NamedTuple}(undef, length(fnames))
    for (ind, field) in enumerate(fnames)
        fieldtype = typeof(getproperty(s, field))
        step = nothing
        if fieldtype <: Real
            input_type = "number"
            step = fieldtype <: Integer ? "1" : "any"
        elseif fieldtype <: AbstractString
            input_type = "text"
        else
            input_type = "text"
        end

        if field in keys(EXPERIMENT_FIELDS)
            lab = EXPERIMENT_FIELDS[field]
        else
            lab = field
        end

        sg_fields[ind] = (
            name = field,
            label = lab,
            type = input_type,
            value = getproperty(s, field),
            step = step,
        )
    end
    return sg_fields
end

#########################

## PAGE FUNCTIONS ##

#########################

function admin()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    experiments = all(Experiment)
    users = find(User; is_admin = false)

    html(:experiments, :admin; users, experiments)
end

function manage()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    user_id = findone(User; username = params(:username)).id

    experiments = all(Experiment)
    added_experiments = find(UserExperiment; user_id = user_id)
    unstarted_experiments = [e for e in added_experiments if e.frac_complete == 0]

    html(
        :experiments,
        :manage;
        added_experiments,
        experiments,
        unstarted_experiments,
        user_id,
    )
end

function create()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/home")))

    full_types = _subtypes(Stimgen)
    stimgen_types = Vector{String}(undef, length(full_types))
    [
        stimgen_types[ind] = split.(type, '.')[end][end] for
        (ind, type) in enumerate(eachrow(string.(full_types)))
    ]

    # From template experiment or not
    if haskey(params(), :template) && !isempty(params(:template))
        ex = findone(Experiment; name = params(:template))
        type = ex.stimgen_type
        stimgen = JSON3.read(ex.stimgen_settings, STIMGEN_MAPPINGS[type])
        exp_fields = get_exp_fields(ex)
        stimgen_fields = get_stimgen_fields(stimgen)
    else
        exp_fields = get_exp_fields()
        stimgen_fields = nothing
        type = nothing
    end

    html(
        :experiments,
        :create;
        stimgen_types,
        exp_fields,
        stimgen_fields,
        type,
    )
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

    # Ensures valid stimgen and hash consistency
    stimgen = JSON3.read(sg_data, STIMGEN_MAPPINGS[sg_type]; parsequoted = true)
    ex = Experiment(; stimgen_settings = JSON3.write(stimgen), stimgen_type = sg_type)

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
            INTERNAL_ERROR,
            """Invalid settings: "$(errors_to_string(validator))".""",
            MIME"application/json",
        )
    end

    # Check for identical experiments
    identical_exp = findone(
        Experiment;
        settings_hash = ex.settings_hash,
        stimgen_type = sg_type,
        n_trials = ex.n_trials,
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
        find(Experiment; settings_hash = ex.settings_hash, stimgen_type = sg_type)

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

end
