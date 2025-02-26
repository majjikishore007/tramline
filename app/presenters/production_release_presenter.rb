class ProductionReleasePresenter < SimpleDelegator
  include Memery

  def initialize(release, view_context = nil)
    @view_context = view_context
    super(release)
  end

  delegate :external_link, to: :store_submission

  def overall_status
    return store_submission_status if store_rollout.blank?
    full_rollout_status
  end

  def last_activity_ts
    (store_rollout || store_submission).updated_at
  end

  def last_activity_tooltip
    "Last activity at #{h.time_format(last_activity_ts)}"
  end

  def store_icon
    "integrations/logo_#{store_submission.provider}.png"
  end

  def h
    @view_context
  end

  private

  def store_submission_status
    case store_submission.status.to_sym
    when :created, :preprocessing, :preparing, :prepared, :submitting_for_review, :cancelling, :cancelled
      {text: "Preparing for release", status: :ongoing}
    when :submitted_for_review
      {text: "Submitted for review", status: :inert}
    when :review_failed
      {text: "Review rejected", status: :failure}
    when :failed, :failed_with_action_required, :failed_prepare
      {text: "Failed to prepare release", status: :failure}
    when :finished_manually
      {text: "Finished manually", status: :inert}
    else
      {text: "Unknown", status: :neutral}
    end
  end

  def full_rollout_status
    percentage = store_rollout.last_rollout_percentage_fmt

    case store_rollout.status.to_sym
    when :created
      {text: "Ready to rollout", status: :ongoing}
    when :started
      {text: "Rolled out to #{percentage}%", status: :ongoing}
    when :failed
      {text: "Failed to rollout out after #{percentage}%", status: :failure}
    when :completed
      {text: "Released", status: :success}
    when :halted
      {text: "Rollout halted at #{percentage}%", status: :inert}
    when :fully_released
      {text: "Released", status: :success}
    when :paused
      {text: "Rollout paused at #{percentage}%", status: :neutral}
    else
      {text: "Unknown", status: :neutral}
    end
  end
end
