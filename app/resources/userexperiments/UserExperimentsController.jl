module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.ControllerHelper
using SearchLight
using SearchLight.Validation
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using Genie.Exceptions


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
        n_trials = findone(Experiment; name = ae.experiment_name).n_trials

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
            :percent_complete => round(100 * ae.trials_complete / n_trials; digits = 2),
            :status => status,
        )
    end
    return ae_data
end

function restart_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")
    instance = jsonpayload("instance")
    user_id = findone(User; username = jsonpayload("username")).id

    # Check if there is another of same experiment with no trials done.
    existing_unstarted =
        find(UserExperiment; experiment_name = name, user_id = user_id, trials_complete = 0)
    if !isempty(existing_unstarted)
        return Router.error(
            INTERNAL_ERROR,
            """Could not restart experiment "$(name)", instance "$(instance)". An unstarted instance of "$(name)" already exists for user "$(username(user_id))".""",
            MIME"application/json",
        )
    end

    experiment = findone(
        UserExperiment;
        experiment_name = name,
        instance = instance,
        user_id = user_id,
    )

    if experiment === nothing
        return Router.error(
            INTERNAL_ERROR,
            """Could not find an experiment with name "$(name)" and instance "$(instance)" for user "$(username(user_id))" to restart.""",
            MIME"application/json",
        )
    end

    trials = find(Trial; experiment_name = name, instance = instance, user_id = user_id)

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
    user_id = findone(User; username = jsonpayload("username")).id

    trials = find(Trial; experiment_name = name, instance = instance, user_id = user_id)

    if !isempty(trials)
        return Router.error(
            INTERNAL_ERROR,
            """Could not remove experiment "$(name)", instance "$(instance)". User "$(username(user_id))" has saved trials.""",
            MIME"application/json",
        )
    end

    ue = findone(
        UserExperiment;
        experiment_name = name,
        instance = instance,
        user_id = user_id,
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
    user_id = findone(User; username = jsonpayload("username")).id

    curr_user_exps = find(UserExperiment; experiment_name = name, user_id = user_id)

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
        user_id = user_id,
        experiment_name = name,
        instance = new_instance,
        trials_complete = 0,
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
        findone(User; username = jsonpayload("username")).id
    catch
        current_user_id()
    end

    if jsonpayload("type") == "UserExperiment"
        added_experiments =
            get_paginated_amount(UserExperiment, limit, page; user_id = user_id)
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

#########################

## PAGE FUNCTIONS ##

#########################

function profile()
    authenticated!()

    init_limit = 2
    init_page = 1
    max_btn_display = 4

    added_experiments = get_paginated_amount(
        UserExperiment,
        init_limit,
        init_page;
        user_id = current_user_id(),
    )
    num_aes =
        count(UserExperiment; user_id = current_user_id()) > 0 ?
        count(UserExperiment; user_id = current_user_id()) : 1

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

end
