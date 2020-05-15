class AddFilingForStimulusToIntakes < ActiveRecord::Migration[6.0]
  def change
    add_column :intakes, :filing_for_stimulus, :integer, default: 0, null: false
  end
end
