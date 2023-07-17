module UsersController

using CharacterizeTinnitus
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using CharacterizeTinnitus.ControllerHelper
using SearchLight
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

function delete_user()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    username = jsonpayload("username")
    user = findone(User; username = username)
    added_experiments = find(UserExperiment; user_id = user.id)

    # Can only delete a user if they do not have any added experiments.
    # May never delete a user if they have any completed experiments.
    if any(
        e -> findone(Experiment; name = e.experiment_name).n_trials <= e.trials_complete,
        added_experiments,
    )
        return json(
            """User "$username" has a completed experiment. Cannot delete this user.""";
            status = 400,
        )
    elseif !isempty(added_experiments)
        return json(
            """User "$username" has added experiments. Clear all experiments before deleting.""";
            status = 400,
        )
    else
        SearchLight.delete(user)
        return json("""User "$username" has been deleted.""")
    end
end

function manage()
    authenticated!()
    current_user().is_admin || throw(ExceptionalResponse(redirect("/profile")))

    init_limit = 2
    init_page = 1
    max_btn_display = 4

    username = params(:username)
    user_id = findone(User; username = username).id

    experiments = all(Experiment)

    num_aes =
        count(UserExperiment; user_id = user_id) > 0 ?
        count(UserExperiment; user_id = user_id) : 1

    max_btn = convert(Int, ceil(num_aes / init_limit))
    if max_btn <= max_btn_display
        table_pages_btns = 1:max_btn
    else
        table_pages_btns = [range(1, max_btn_display - 1)..., "...", max_btn]
    end

    unstarted_experiments = [e for e in find(UserExperiment; user_id = user_id) if e.trials_complete == 0]

    ae_disp = get_paginated_amount(
        UserExperiment,
        init_limit,
        init_page;
        user_id = user_id,
    )
    ae_data = ue2dict(ae_disp)

    html(
        :experiments,
        :manage;
        experiments,
        unstarted_experiments,
        ae_data,
        username,
        num_aes,
        table_pages_btns,
        init_limit,
        init_page,
    )
end

end
