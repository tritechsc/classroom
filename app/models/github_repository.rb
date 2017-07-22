# frozen_string_literal: true

class GitHubRepository < GitHubResource
  # NOTE: LEGACY, DO NOT REMOVE.
  # This is needed for the lib/collab_migration.rb
  def add_collaborator(collaborator, options = {})
    GitHub::Errors.with_error_handling do
      @client.add_collaborator(@id, collaborator, options)
    end
  end

  def get_starter_code_from(source)
    GitHub::Errors.with_error_handling do
      options = {
        vcs:          "git",
        accept:       Octokit::Preview::PREVIEW_TYPES[:source_imports],
        vcs_username: @client.login,
        vcs_password: @client.access_token
      }

      @client.start_source_import(@id, "https://github.com/#{source.full_name}", options)
    end
  end

  def import_progress(**options)
    GitHub::Errors.with_error_handling do
      @client.source_import_progress(full_name, options)
    end
  end

  # Public: Invite a user to a GitHub repository.
  #
  # user - The String GitHub login for the user.
  #
  # Returns an Integer Invitation id, or raises a GitHub::Error.
  def invite(user, **options)
    GitHub::Errors.with_error_handling do
      options[:accept] = Octokit::Preview::PREVIEW_TYPES[:repository_invitations]
      @client.invite_user_to_repository(@id, user, options)
    end
  end

  # Public: Add a label to a GitHub repository.
  #
  # label - The String name of the label.
  # color -  (defaults to: "ffffff")  A color, in hex, without the leading #
  #
  # Returns a Hash of the label, or raises a GitHub::Error.
  def add_label(label, color = "ffffff", options = {})
    GitHub::Errors.with_error_handling do
      @client.add_label(full_name, label, color, options)
    end
  end

  # Public: Add a label(s) to an issue.
  #
  # number - Number ID of the issue
  # labels - An array of labels to apply to this Issue
  #
  # Returns A list of the labels currently on the issue, or raises a GitHub::Error.
  def add_labels_to_issue(number, labels)
    GitHub::Errors.with_error_handling do
      @client.add_labels_to_an_issue(full_name, number, labels)
    end
  end

  # Public: Add issues to the GitHub repository.
  #
  # title    - The title of the issue.
  # body     - The body of the issue.
  #
  # Returns the newly created issue, or raises a GitHub::Error.
  def add_issue(title, body, **options)
    GitHub::Errors.with_error_handling do
      @client.create_issue(full_name, title, body, options)
    end
  end

  # Public: Get a tree object from the GitHub repository.
  #
  # sha    - sha of the tree.
  #
  # Returns a git Tree object, or empty hash.
  def tree(sha, **options)
    GitHub::Errors.with_error_handling do
      @client.tree(full_name, sha, options)
    end
  rescue GitHub::Error
    {}
  end

  # Public: Get a blob from the GitHub repository.
  #
  # sha    - The string sha value of the blob.
  #
  # Returns a GitHubBlob instance, or raises a GitHub::Error.
  def blob(sha, **options)
    GitHub::Errors.with_error_handling do
      @blob = GitHubBlob.new(self, sha, options)
    end
  end

  def default_branch
    GitHub::Errors.with_error_handling do
      repository = @client.repository(full_name)

      repository[:default_branch]
    end
  end

  def branch(name, **options)
    GitHub::Errors.with_error_handling do
      @client.branch(full_name, name, options)
    end
  rescue GitHub::Error
    {}
  end

  def branch_tree(name, **options)
    GitHub::Errors.with_error_handling do
      branch_sha = branch(name).commit.sha
      tree(branch_sha, options)
    end
  rescue GitHub::Error
    {}
  end

  def remove_branch(name, **options)
    GitHub::Errors.with_error_handling do
      @client.delete_branch(full_name, name, options)
    end
  end

  def commits(branch)
    GitHub::Errors.with_error_handling do
      @client.commits(full_name, sha: branch)
    end
  rescue GitHub::Error
    []
  end

  def commits_url(branch)
    html_url + "/commits/" + branch
  end

  def tree_url_for_sha(sha)
    html_url + "/tree/" + sha
  end

  def present?(**options)
    self.class.present?(@client, @id, options)
  end

  # Public: Checks if the GitHub repository has a given branch.
  #
  # branch    - name of the branch to check for
  #
  # Returns true if branch exists, false otherwise
  def branch_present?(branch, **options)
    GitHub::Errors.with_error_handling do
      @client.branches(full_name, options).map(&:name).include? branch
    end
  rescue GitHub::Error
    false
  end

  def public=(is_public)
    GitHub::Errors.with_error_handling do
      @client.update(full_name, private: !is_public)
    end
  end

  def self.present?(client, full_name, **options)
    GitHub::Errors.with_error_handling do
      client.repository?(full_name, options)
    end
  rescue GitHub::Error
    false
  end

  def self.find_by_name_with_owner!(client, full_name)
    GitHub::Errors.with_error_handling do
      repository = client.repository(full_name)
      GitHubRepository.new(client, repository.id)
    end
  end

  private

  def github_attributes
    %w[name full_name html_url]
  end
end
