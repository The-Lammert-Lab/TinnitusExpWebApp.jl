module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Trials
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using SearchLight.Validation
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using Genie.Exceptions

function restart_exp()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    name = jsonpayload("name")
    instance = jsonpayload("instance")
    user_id = parse(Int, jsonpayload("user_id"))

    # Check if there is another of same experiment with no trials done.
    existing_unstarted =
        find(UserExperiment; experiment_name = name, user_id = user_id, frac_complete = 0)
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

    experiment.frac_complete = 0.0
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
    user_id = parse(Int, jsonpayload("user_id"))

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
    user_id = parse(Int, jsonpayload("user_id"))

    curr_user_exps = find(UserExperiment; experiment_name = name, user_id = user_id)

    # Check request validity (can't add experiment if unstarted already exists)
    if any(i -> i == 0, getproperty.(curr_user_exps, :frac_complete))
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
        frac_complete = 0.0,
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

#########################

## PAGE FUNCTIONS ##

#########################

function profile()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    user = current_user()
    is_admin = user.is_admin
    username = user.username
    html(:userexperiments, :profile; added_experiments, is_admin, username)
end

end
