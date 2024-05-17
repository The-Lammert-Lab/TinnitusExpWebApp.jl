module CreateTableThresholds
import SearchLight.Migrations:
    create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
    create_table(:thresholds) do
        [
            pk()
            columns([
                :user_id => :int,
                :freq => :float,
                :threshold => :float,
            ])
        ]
    end
end


function down()
    drop_table(:thresholds)
end

end