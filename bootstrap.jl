(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using CharacterizeTinnitus
const UserApp = CharacterizeTinnitus
CharacterizeTinnitus.main()
