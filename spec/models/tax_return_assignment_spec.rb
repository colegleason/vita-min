# == Schema Information
#
# Table name: tax_return_assignments
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assigner_id   :bigint
#  tax_return_id :bigint           not null
#
# Indexes
#
#  index_tax_return_assignments_on_assigner_id    (assigner_id)
#  index_tax_return_assignments_on_tax_return_id  (tax_return_id)
#
# Foreign Keys
#
#  fk_rails_...  (assigner_id => users.id)
#  fk_rails_...  (tax_return_id => tax_returns.id)
#
require 'rails_helper'

RSpec.describe TaxReturnAssignment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
