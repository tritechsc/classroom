# frozen_string_literal: true

class GlobalRelayIdBackfill
  attr_accessor :repo

  def initialize(repo)
    @repo = repo
  end

  # rubocop:disable AbcSize
  def backfill_global_relay_id
    return if repo.global_relay_id

    global_relay_id = fetch_global_relay_id

    unless global_relay_id
      Rails.logger.error "Assignment Repo no longer exists: #{repo.id}" && return
    end

    repo.global_relay_id = global_relay_id
    repo.save!
  rescue => e
    Rails.logger.error "Error while running assignment global relay id backfill for repo: #{repo.id}"
    Rails.logger.error e
  end
  # rubocop:enable AbcSize

  def fetch_global_relay_id
    client = repo.user.github_graphql_client

    response = client.query GitHub::GraphQL::Queries::ID_FOR_ASSIGNMENT_REPO,
                            name: repo.github_repository.name,
                            owner: repo.organization.github_organization.login

    response&.repository&.id
  end
end
