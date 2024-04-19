module AddColumnsMultAndBinrangeToUserexperiments

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
    add_columns(:userexperiments, [:mult => :float])
    add_columns(:userexperiments, [:binrange => :int])
end

function down()
    remove_columns(:userexperiments, [:mult])
    remove_columns(:userexperiments, [:binrange])
end

end
