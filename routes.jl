using Genie.Router
using CharacterizeTinnitus.BlocksController
using CharacterizeTinnitus.UserExperimentsController

route("/", BlocksController.index)
route("/expsetup", BlocksController.expsetup)
route("/experiment", BlocksController.experiment)
route("/rest", BlocksController.rest)
route("/generate", BlocksController.gen_stim_rest; method = POST)
route("/done", BlocksController.done)
route("/save", BlocksController.save_responses; method = POST)

route("/home", UserExperimentsController.home)
route("add", UserExperimentsController.add_exp; method = POST)
route("/restart", UserExperimentsController.restart_exp; method = POST)
route("/remove", UserExperimentsController.remove_exp; method = POST)