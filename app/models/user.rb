class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :league_users
  has_many :leagues, through: :league_users
  has_many :entries
  has_many :notification_type_users
  has_many :notification_types, through: :notification_type_users

  validates :name, presence: true, uniqueness: true

  def to_s
    self.email
  end

  def admin?
    self.admin == true
  end

end
