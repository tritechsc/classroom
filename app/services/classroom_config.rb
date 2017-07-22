# frozen_string_literal: true

class ClassroomConfig
  CONFIGURABLES = %w[issues labels].freeze

  attr_reader :github_repository

  def initialize(github_repository)
    raise ArgumentError, "Invalid configuration repo" unless github_repository.branch_present? "github-classroom"
    @github_repository = github_repository
  end

  def setup_repository(repo)
    configs_tree = @github_repository.branch_tree("github-classroom")
    configs_tree.tree.each do |config|
      send("generate_#{config.path}", repo, config.sha) if CONFIGURABLES.include? config.path
    end

    repo.remove_branch("github-classroom")
    true
  rescue GitHub::Error
    false
  end

  def configurable?(repo)
    repo.branch_present?("github-classroom")
  end

  private

  # Internal: Generates issues for the assignment_repository based on the configs
  #
  # repo - GitHubRepository for which to perform the configuration
  #                   setups
  # tree_sha     - sha of the "issues" tree
  #
  # Returns nothing
  def generate_issues(repo, tree_sha)
    @github_repository.tree(tree_sha).tree.each do |issue|
      blob = @github_repository.blob(issue.sha)

      next if blob.data.blank?

      issue = repo.add_issue(blob.data["title"], blob.body)
      labels = blob.data["labels"] || []
      repo.add_labels_to_issue(issue.number, labels)
    end
  end

  # Internal: Generates labels for the assignment_repository based on the configs
  #
  # repo - GitHubRepository for which to perform the configuration
  #                   setups
  # tree_sha     - sha of the "labels" tree
  #
  # Returns nothing
  def generate_labels(repo, tree_sha)
    @github_repository.tree(tree_sha).tree.each do |label|
      blob = @github_repository.blob(label.sha)

      next if blob.data.blank?

      color = blob.data["color"] || "ffffff"
      repo.add_label(blob.data["label"], color)
    end
  end

  # Internal: Configuration priority
  # 0 being highest priority
  #
  # Returns Hash of priorities
  def priority
    { "labels" => 0, "issues" => 1 }
  end

  # Internal: Sort the configs to be ordered by priority
  #
  # Returns a list of configs
  def sorted_configs(tree)
    tree.sort { |a, b| priority[a.path] <=> priority[b.path] }
  end
end
