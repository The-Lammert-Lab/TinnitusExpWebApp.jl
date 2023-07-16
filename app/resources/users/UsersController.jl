module UsersController

using CharacterizeTinnitus
using CharacterizeTinnitus.Users
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using Genie.Exceptions

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

end
