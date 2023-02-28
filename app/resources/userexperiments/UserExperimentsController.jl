module UserExperimentsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Experiments
using CharacterizeTinnitus.UserExperiments
using SearchLight
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using GenieAuthentication

function home()
    authenticated!()
    added_experiments = find(UserExperiment; user_id = current_user_id())
    visible_experiments = find(Experiment; visible = true)
    html(:userexperiments, :home; added_experiments, visible_experiments)
end

end