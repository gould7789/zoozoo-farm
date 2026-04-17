class AddHiddenToAnimalCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :animal_categories, :hidden, :boolean, null: false, default: false
  end
end
