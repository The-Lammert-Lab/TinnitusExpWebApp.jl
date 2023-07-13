using Genie.Router
using CharacterizeTinnitus.TrialsController
using CharacterizeTinnitus.ExperimentsController
using CharacterizeTinnitus.UserExperimentsController
using CharacterizeTinnitus.PublicController

route("/experiment", TrialsController.experiment)
route("/rest", TrialsController.rest)
route("/generate", TrialsController.gen_stim_rest; method = POST)
route("/done", TrialsController.done)
route("/save", TrialsController.save_response; method = POST)

route("/admin", ExperimentsController.admin)
route("/admin/view", ExperimentsController.view_exp; method = POST)
route("/admin/getpartialdata", ExperimentsController.get_partial_data; method = POST)
route("/manage", ExperimentsController.manage)
route("/create", ExperimentsController.create)
route("/create/get", ExperimentsController.get_stimgen)
route("/create/save", ExperimentsController.save_exp; method = POST)
route("/delete", ExperimentsController.delete_exp; method = POST)

route("/profile", UserExperimentsController.profile)
route("/add", UserExperimentsController.add_exp; method = POST)
route("/restart", UserExperimentsController.restart_exp; method = POST)
route("/remove", UserExperimentsController.remove_exp; method = POST)

route("/", PublicController.index)
route("/FAQ", PublicController.faq)
route("/lab", PublicController.lab)
