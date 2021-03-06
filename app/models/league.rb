require 'byebug'

class League < ActiveRecord::Base
  belongs_to :user
  has_many :league_users
  has_many :users, through: :league_users
  has_many :entries
  has_many :hits, through: :entries

  validates :name, :starts_at, presence: true

  scope :started, -> { where('starts_at <= ?', Time.now)  }
  scope :full, -> { joins(:entries).where('entries.cancelled_at IS NULL').group('leagues.id').having('COUNT(entries.id) = ?', Team.count) }
  scope :complete, -> { joins(:entries).where('entries.won_at IS NOT NULL').group('leagues.id') }

  def available_teams
    Team.all - entries.active.map(&:team)
  end

  def get_and_record_winners!
    winners = []

    # Find each entry's number of hits and games
    standings_sql = """SELECT entries.id entry_id, COUNT(DISTINCT hits.id) hits, COUNT(DISTINCT games.id) games
          FROM entries
          LEFT JOIN hits ON hits.entry_id = entries.id
          LEFT JOIN games ON games.home_team_id = entries.team_id OR games.away_team_id = entries.team_id
          WHERE entries.league_id = #{id}
          AND entries.cancelled_at IS NULL
          GROUP BY entries.id"""
    standings = ActiveRecord::Base.connection.execute(standings_sql)

    # Check for 1st and 2nd place winners
    2.times do |place|
      if place == 0 && entries.winners_in_place(1).any? # We already have a 1st place winner
        return []
      elsif place == 1 && entries.winners_in_place(1).empty? # Don't pick 2nd place winner if we can't decide on 1st
        return []
      end

      # Find possible winners, those little s['hits']...
      # TODO: Handle if 2nd place has < 13 runs
      possible_winners = standings.select { |s| s['hits'] == (14 - place) }

      # See if anyone else could catch up to win/tie
      if possible_winners.any?
        game_counts = possible_winners.collect { |pw| pw['games'] }
        entry_ids = possible_winners.collect{ |pw| pw['entry_id'] }
        contenders = standings.select { |s| s['hits'] + game_counts.min - s['games'] >= (14 - place) }
        contenders.reject! { |c| entry_ids.include?(c['entry_id']) }

        # If one can possibly catch up then let's declare winners
        if contenders.empty?
          possible_winners.each do |pw|
            entry = Entry.find(pw['entry_id'])
            entry.won_at = Time.now
            entry.won_place = place + 1
            entry.save
            winners << entry
          end
        end
      end
    end

    winners
  end

  def losers
    entries.where(won_at: nil)
  end

end
