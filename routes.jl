using Genie.Router
using CharacterizeTinnitus.TrialsController
using CharacterizeTinnitus.ExperimentsController
using CharacterizeTinnitus.UserExperimentsController
using CharacterizeTinnitus.UsersController
using CharacterizeTinnitus.PublicController
using CharacterizeTinnitus.RatingsController
using CharacterizeTinnitus.ThresholdController
using CharacterizeTinnitus.LoudnessController
using CharacterizeTinnitus.PitchController


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

route("/thresholdDetermination", ThresholdController.threshold_determination)
route("/getPureTone", ThresholdController.get_pure_tone; method=POST)
route("/saveThreshold", ThresholdController.save_threshold; method=POST)

route("/loudnessMatching", LoudnessController.loudness_matching)
route("/getPureToneLM", LoudnessController.get_pure_tone; method=POST)
route("/saveLM", LoudnessController.save_lm; method=POST)

route("/pitchMatching", PitchController.pitch_matching)
route("/octaveDetermination", PitchController.get_pure_tone_for_oct_determination; method=POST)
route("/inOctave", PitchController.get_pure_tone_for_oct_determination; method=POST)

route("/saveSoundForOctaveDetermination", PitchController.save_sound_for_octave_determination; method=POST)
route("/getInOctaveFreqs", PitchController.get_in_octave_freqs; method=POST)
route("/getOctConfusionFreqs", PitchController.get_oct_confusion_freqs; method=POST)
route("/setCalibratedValue", PitchController.set_calibrated_value; method=POST)