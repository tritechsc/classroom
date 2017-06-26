# frozen_string_literal: true

require 'rails_helper'

describe GlobalRelayIdBackfill do
  let(:user)         { classroom_student }

  # rails
  let(:organization) { create(:organization, github_id: 4223) }
  let(:assignment)   { create(:assignment, organization: organization) }

  describe '#backfill_global_relay_id', :vcr do
    context 'when the assignment repo exists on GitHub' do
      # rails
      let(:assignment_repo) { create(:assignment_repo, github_repo_id: 8514, assignment: assignment, user: user) }

      context 'when the assignment repo already has a global relay id' do
        before do
          assignment_repo.global_relay_id = 'GLOBAL RELAY ID'
          assignment_repo.save

          described_class.new(assignment_repo).backfill_global_relay_id
        end

        it 'does not modify the id' do
          expect(assignment_repo.reload.global_relay_id).to eq('GLOBAL RELAY ID')
        end

        it 'does not make a request to the graphql endpoint' do
          expect(WebMock).to_not have_requested(:post, GitHub::GraphQL::ENDPOINT_URL)
        end
      end

      context 'when the assignment repo does not have a global relay id' do
        before do
          assignment_repo.global_relay_id = nil
          described_class.new(assignment_repo).backfill_global_relay_id
        end

        it 'makes a request to graphql' do
          expect(WebMock).to have_requested(:post, GitHub::GraphQL::ENDPOINT_URL)
        end

        it 'sets the global relay id' do
          expect(assignment_repo.reload.global_relay_id).to be_truthy
        end
      end

      context 'when the users token is bad' do
        before do
          user.token = 'Potato'
          user.save
        end

        it 'does not throw an exception' do
          expect do
            described_class.new(assignment_repo).backfill_global_relay_id
          end.to_not raise_error
        end
      end
    end

    context 'when the assignment repo does not exist on GitHub' do
      let(:assignment_repo) { create(:assignment_repo, github_repo_id: -1, assignment: assignment, user: user) }

      it 'does not throw an exception' do
        expect do
          described_class.new(assignment_repo).backfill_global_relay_id
        end.to_not raise_error
      end
    end
  end
end
