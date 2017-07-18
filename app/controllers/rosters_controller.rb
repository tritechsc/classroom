# frozen_string_literal: true

class RostersController < ApplicationController
  before_action :ensure_student_identifier_flipper_is_enabled, :set_organization
  before_action :set_roster, :redirect_if_no_roster, :set_unlinked_users, only: [:show]

  def show; end

  def new
    @roster = Roster.new
  end

  def create
    @roster = Roster.new(identifier_name: params[:identifier_name])

    add_identifiers_to_roster

    @roster.save!
    @organization.roster = @roster
    @organization.save!

    flash[:success] = "Your classroom roster has been saved! Manage it <a href='#{roster_url(@organization)}'>here</a>."

    redirect_to organization_path(@organization)
  rescue ActiveRecord::RecordInvalid
    render :new
  end

  def link
    user = User.find(params[:user_id])
    roster_entry = RosterEntry.find(params[:roster_entry_id])

    roster_entry.user = user
    roster_entry.save!

    flash[:success] = "Student and GitHub account linked!"
    redirect_to roster_path(@organization)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error has occured, please try again."
    redirect_to roster_path(@organization)
  end

  def unlink
    roster_entry = RosterEntry.find(params[:roster_entry_id])

    roster_entry.user = nil
    roster_entry.save!

    flash[:success] = "Student and GitHub account unlinked!"
    redirect_to roster_path(@organization)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error has occured, please try again."
    redirect_to roster_path(@organization)
  end

  private

  def redirect_if_no_roster
    return if @roster

    redirect_to new_roster_url(@organization)
  end

  def set_organization
    @organization = Organization.find_by!(slug: params[:id])
  end

  def set_roster
    @roster = @organization.roster
  end

  # An unlinked user is a user who:
  # - Is a user on an assignment or group assignment belonging to the org
  # - Is not on the organization roster
  def set_unlinked_users
    group_assignment_users = @organization.repo_accesses.map(&:user)
    assignment_users = @organization.assignments.map(&:users).flatten.uniq

    roster_entry_users = @roster.roster_entries.map(&:user).compact

    @unlinked_users = (group_assignment_users + assignment_users).uniq - roster_entry_users
  end

  def add_identifiers_to_roster
    identifiers = split_identifiers(params[:identifiers])
    identifiers.each do |identifier|
      @roster.roster_entries << RosterEntry.new(identifier: identifier)
    end
  end

  def split_identifiers(raw_identifiers_string)
    raw_identifiers_string.split("\r\n").reject(&:blank?).uniq
  end
end
