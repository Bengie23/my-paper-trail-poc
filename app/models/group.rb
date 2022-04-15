class Group < ApplicationRecord

    has_many :partner_groups
    has_many :partners, through: :partner_groups
end
