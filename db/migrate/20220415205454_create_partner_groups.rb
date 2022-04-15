class CreatePartnerGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :partner_groups do |t|
      t.references :group, foreign_key: true
      t.references :partner, foreign_key: true

      t.timestamps
    end
  end
end
