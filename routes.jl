using Genie.Router
using CharacterizeTinnitus.TrialsController
using CharacterizeTinnitus.ExperimentsController
using CharacterizeTinnitus.UserExperimentsController
using CharacterizeTinnitus.UsersController
using CharacterizeTinnitus.PublicController
using CharacterizeTinnitus.RatingsController

route("/experiment", TrialsController.experiment)
route("/rest", TrialsController.rest)
route("/generate", TrialsController.gen_stim_rest; method=POST)
route("/done", TrialsController.done)
route("/save", TrialsController.save_response; method=POST)

route("/admin", ExperimentsController.admin)
route("/admin/view", ExperimentsController.view_exp; method=POST)
route("/admin/getpartialdata", ExperimentsController.get_partial_data; method=POST)
route("/create", ExperimentsController.create)
route("/create/get", ExperimentsController.get_stimgen)
route("/create/save", ExperimentsController.save_exp; method=POST)
route("/delete", ExperimentsController.delete_exp; method=POST)

route("/manage/delete", UsersController.delete_user; method=POST)
route("/manage", UsersController.manage)

route("/profile", UserExperimentsController.profile)
route("/adjustResynth", UserExperimentsController.adjust_resynth)
route("/likertQuestions", UserExperimentsController.likert_questions)
route("/getAdjustedResynthAudio", UserExperimentsController.play_adjusted_audio; method=POST)
route("/saveMultandBinrange", UserExperimentsController.save_mult_and_binrange; method=POST)
route("/add", UserExperimentsController.add_exp; method=POST)
route("/restart", UserExperimentsController.restart_exp; method=POST)
route("/remove", UserExperimentsController.remove_exp; method=POST)
route("/getpartialdata", UserExperimentsController.get_partial_data; method=POST)

route("/saveLikertRating", RatingsController.save_likert_rating; method=POST)

route("/", PublicController.index)
route("/FAQ", PublicController.faq)
route("/lab", PublicController.lab)
route("/calibrate", PublicController.calibrate)