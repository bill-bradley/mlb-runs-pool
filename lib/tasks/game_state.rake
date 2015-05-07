require 'game_state'

namespace :game_state do

  desc "Assign a team to each unassigned entry"
  task assign_teams: :environment do
    entries = Entry.unassigned
    entries.each do |entry|
      entry.team = entry.league.available_teams.sample
      entry.save
    end
  end

  desc "Create hits based on existing games for one date"
  task :create_hits, [:query_date] => [:environment] do |t, args|
    GameState.create_hits(args.query_date)
  end

  desc "Reset the games, hits and won_at column on entries"
  task reset: :environment do
    Game.destroy_all
    Hit.destroy_all
    Entry.where.not(won_at: nil).each do |entry|
      entry.won_at = nil
      entry.save
    end
  end

  desc "Give everyone the default notification types"
  task assign_notifications: :environment do
    NotificationType.all.each do |notification_type|
      User.all.each do |user|
        NotificationTypeUser.find_or_create_by(user: user, notification_type: notification_type)
      end
    end
  end
end
