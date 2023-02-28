using Genie.Router
using CharacterizeTinnitus.BlocksController
using CharacterizeTinnitus.UserExperimentsController

route("/", BlocksController.index)
route("/expsetup", BlocksController.expsetup)
route("/experiment", BlocksController.experiment)
route("/rest", BlocksController.rest)
route("/done", BlocksController.done)
route("/save/:id::Int", BlocksController.save_responses; method = POST)

route("/home", UserExperimentsController.home)