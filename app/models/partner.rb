class Partner < ApplicationRecord
    has_many :partner_groups
    has_many :groups, through: :partner_groups
end
