class App < ApplicationRecord
  has_paper_trail
  extend FriendlyId

  belongs_to :organization, class_name: "Accounts::Organization", optional: false
  has_many :integrations, inverse_of: :app, dependent: :destroy
  has_many :trains, class_name: "Releases::Train", dependent: :destroy
  has_many :sign_off_groups, dependent: :destroy
  has_one :config, class_name: "AppConfig", dependent: :destroy

  validates :bundle_identifier, uniqueness: {scope: :organization_id}
  validates :build_number, numericality: {greater_than_or_equal_to: :build_number_was}, on: :update
  validate :no_trains_are_running, on: :update

  enum platform: {android: "android", ios: "ios"}

  accepts_nested_attributes_for :sign_off_groups, allow_destroy: true, reject_if: proc { |attributes| attributes["name"].blank? }

  after_initialize :initialize_config, if: :new_record?
  after_initialize :set_default_platform, if: :new_record?

  friendly_id :name, use: :slugged

  delegate :vcs_provider, to: :integrations
  delegate :ci_cd_provider, to: :integrations
  delegate :notification_provider, to: :integrations

  scope :with_trains, -> { joins(:trains).distinct }

  def active_runs
    Releases::Train::Run.on_track.joins(train: :app).where(train: {app: self})
  end

  def ready?
    integrations.ready? and config&.ready?
  end

  def set_default_platform
    self.platform = App.platforms[:android]
  end

  def initialize_config
    build_config
  end

  def bump_build_number!
    self.build_number = build_number + 1
    save!
    build_number.to_s
  end

  def no_trains_are_running
    if trains.running? && bundle_identifier_changed?
      errors.add(:bundle_identifier, "cannot be updated if there are running trains!")
    end
  end
end
