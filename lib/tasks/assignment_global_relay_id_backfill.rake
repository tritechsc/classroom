# frozen_string_literal: true

require_relative '../global_relay_id_backfill'

task assignment_global_relay_id_backfill: :environment do
  AssignmentRepo.find_in_batches(batch_size: 100) do |repos|
    repos.each do |repo|
      fetch_global_relay_id(repo)
    end
  end
end
