module RatingsController

using CharacterizeTinnitus
using CharacterizeTinnitus.Ratings
using SearchLight
using SearchLight.Validation
using Genie.Renderers, Genie.Renderers.Html
using Genie.Router, Genie.Requests
using Genie.Renderers.Json
using GenieAuthentication
using Genie.Exceptions
using GenieSession
using TinnitusReconstructor


function save_likert_rating()
    instance = parse(Int, params(:instance))
    rating = parse(Int, params(:rating))
    audio = params(:audio_type)

    query_str = "SELECT max(id) as max_id FROM ratings WHERE experiment_name = \'$(params(:name))\' and instance = $(instance) and user_id = $(current_user_id())"

    max_id = SearchLight.query(query_str)[1, 1]

    println(typeof(max_id))
    println(max_id)

    if ismissing(max_id)
        max_id = 0
    end

    curr_ratings_instance = findone(
        Rating;
        id=max_id,
        experiment_name=params(:name),
        instance=instance,
        user_id=current_user_id(),
    )

    if isnothing(curr_ratings_instance) || ismissing(curr_ratings_instance)
        curr_ratings_instance = Rating(
            user_id=current_user_id(),
            experiment_name=params(:name),
            instance=instance)
        setproperty!(curr_ratings_instance, Symbol(audio), rating)
        save(curr_ratings_instance)
    else
        if getproperty(curr_ratings_instance, Symbol(audio)) == -1
            setproperty!(curr_ratings_instance, Symbol(audio), rating)
            save(curr_ratings_instance)
        else
            new_ratings_instance = Rating(
                user_id=current_user_id(),
                experiment_name=params(:name),
                instance=instance,)
            setproperty!(new_ratings_instance, Symbol(audio), rating)
            save(new_ratings_instance)
        end
    end
end

end