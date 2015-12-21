Sequel.migration do
  up do
    run "create index series_register_id_date_part_hour_idx on series(time, date_part('hour',time))"
  end

  down do
    alter_table(:series) do
      drop_index name: 'series_register_id_date_part_hour_idx'
    end
  end
end
