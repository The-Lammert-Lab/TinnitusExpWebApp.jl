module AddRatingColumnsToUserexperiments

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:userexperiments, [:white_noise => :string])
    add_columns(:userexperiments, [:standard_resynth => :string])
    add_columns(:userexperiments, [:adjusted_resynth => :string])

end

function down()
    remove_columns(:userexperiments, [:white_noise])
    remove_columns(:userexperiments, [:standard_resynth])
    remove_columns(:userexperiments, [:adjusted_resynth])
end

end
