# frozen_string_literal: true
require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  setup do
    @organization = organization(:classroom)
  end

  test '.default_scope hides deleted records' do
    @organization.update_attributes(deleted_at: Time.zone.now)
    refute_includes Organization.all, @organization
  end

  # Presence
  %w(github_id title).each do |column|
    test "#{column} must be present" do
      @organization.send("#{column}=", nil)
      refute @organization.valid?
    end
  end

  # Uniqueness
  test 'has a unique github_id' do
    other_organization = Organization.create(
      github_id: @organization.github_id,
      title: 'Classroom for geniuses'
    )

    refute other_organization.valid?
  end

  test 'has a unique slug' do
    # The slug is created with the id and the title
    other_organization = Organization.create(
      github_id: @organization.github_id,
      title: @organization.title
    )

    refute other_organization.valid?
  end

  test '#all_assignments returns an Array of Assignments and GroupAssignments' do
    assert all_assignments = @organization.all_assignments
    assert_kind_of Array, all_assignments

    @organization.assignments.each do |assignment|
      assert_includes all_assignments, assignment
    end

    @organization.group_assignments.each do |group_assignment|
      assert_includes all_assignments, group_assignment
    end
  end

  test '#flipper_id should include the organizations id' do
    assert_equal "Organization:#{@organization.id}", @organization.flipper_id
  end

  test '#github_client returns an Octokit::Client with an access token' do
    assert_kind_of Octokit::Client, @organization.github_client
    assert @organization.github_client.access_token.present?
  end

  test '#github_organization returns the Organizations presence on GitHub' do
    assert_kind_of GitHubOrganization, @organization.github_organization
    assert_equal @organization.github_organization.id, @organization.github_id
  end

  test 'destroys the GitHub organization webhook on #destroy' do
    @organization.update_attributes(webhook_id: 9_999_999, is_webhook_active: true)
    @organization.destroy

    assert_requested :delete, github_url("/organizations/#{@organization.github_id}/hooks/#{@organization.webhook_id}")
  end
end
