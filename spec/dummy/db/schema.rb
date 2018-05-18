ActiveRecord::Schema.define(version: 1) do
  create_table 'people', force: :cascade do |t|
    t.string   'first_name', limit: 255, null: false
    t.string   'last_name',  limit: 255, null: false
    t.date     'birthdate'
    t.datetime 'updated_at'
    t.datetime 'created_at'
  end

  create_table 'emails', force: :cascade do |t|
    t.integer  'person_id', limit: 4,  null: false
    t.string   'address',   limit: 64, null: false
    t.datetime 'updated_at'
    t.datetime 'created_at'
  end

  create_table 'messages', force: :cascade do |t|
    t.string   'body',      limit: 32, null: false
    t.integer  'email_id',  limit: 4,  null: false
    t.datetime 'sent_at',              null: false
    t.datetime 'updated_at'
    t.datetime 'created_at'
  end
end
