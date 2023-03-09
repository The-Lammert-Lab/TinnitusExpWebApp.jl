using Genie.Router
using CharacterizeTinnitus.TrialsController
using CharacterizeTinnitus.UserExperimentsController

route("/", TrialsController.index)
route("/expsetup", TrialsController.expsetup)
route("/experiment", TrialsController.experiment)
route("/rest", TrialsController.rest)
route("/generate", TrialsController.gen_stim_rest; method = POST)
route("/done", TrialsController.done)
route("/save", TrialsController.save_response; method = POST)

route("/home", UserExperimentsController.home)
route("/add", UserExperimentsController.add_exp; method = POST)
# route("/restart", UserExperimentsController.restart_exp; method = POST)
route("/remove", UserExperimentsController.remove_exp; method = POST)