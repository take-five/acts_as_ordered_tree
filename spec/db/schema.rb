ActiveRecord::Schema.define(:version => 0) do
  create_table :categories, :force => true do |t|
    t.column :name, :string
    t.column :parent_id, :integer
    t.column :position, :integer
    t.column :depth, :integer
    t.column :categories_count, :integer
  end

  create_table :renamed_columns, :force => true do |t|
    t.column :name, :string
    t.column :mother_id, :integer
    t.column :red, :integer
    t.column :pitch, :integer
  end

  create_table :scoped, :force => true do |t|
    t.column :scope_type, :string
    t.column :name, :string
    t.column :parent_id, :integer
    t.column :position, :integer
  end
end