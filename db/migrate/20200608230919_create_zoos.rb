class CreateZoos < ActiveRecord::Migration[5.2]
  def change
    create_table :zoos do |t|
      t.string :name 
      t.integer :end_money 
      t.integer :zookeeper_id 
    end 
  end
end
