using Genie.Router
using CharacterizeTinnitus.BlocksController

route("/", BlocksController.index)
route("/expsetup", BlocksController.expsetup)
route("/exptest", BlocksController.exptest)