module CreateTableRatings
import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()

    create_table(:ratings) do
        [
            primary_key()
            column(:user_id, :int)
            column(:experiment_name, :string)
            column(:instance, :int)
            column(:white_noise, :int)
            column(:standard_resynth, :int)
            column(:adjusted_resynth, :int)
        ]
    end

end

function down()
    drop_table(:ratings)
end

end
