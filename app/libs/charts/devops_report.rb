class Charts::DevopsReport
  include Memery
  include Loggable
  using RefinedString

  def self.warm(train) = new(train).warm

  def self.all(train) = new(train).all

  def initialize(train)
    @train = train
    @organization = train.organization
    @team_colors = organization.team_colors
  end

  def warm
    cache.write(cache_key, report)
  rescue => e
    elog(e)
  end

  def all
    cache.fetch(cache_key)
  end

  def report
    {
      refreshed_at: Time.current,
      mobile_devops: {
        duration: {
          data: duration,
          type: "area",
          value_format: "time",
          name: "devops.duration"
        },
        frequency: {
          data: frequency,
          type: "area",
          value_format: "number",
          name: "devops.frequency"
        },
        time_in_review: {
          data: time_in_review,
          type: "area",
          value_format: "time",
          name: "devops.time_in_review"
        },
        hotfixes: {
          data: hotfixes,
          type: "area",
          value_format: "number",
          name: "devops.hotfixes"
        },
        time_in_phases: {
          data: time_in_phases,
          stacked: true,
          type: "stacked-bar",
          value_format: "time",
          name: "devops.time_in_phases",
          height: "250"
        },
        reldex_scores: {
          data: reldex_scores,
          type: "line",
          value_format: "number",
          name: "devops.reldex",
          height: "250",
          show_y_axis: true,
          y_annotations: [
            {y: 0..train.release_index.tolerable_range.min, text: "Mediocre", color: "mediocre"},
            {y: train.release_index.tolerable_range.max, text: "Excellent", color: "excellent"}
          ]
        }
      },
      operational_efficiency: {
        stability_contributors: {
          data: release_stability_contributors,
          type: "line",
          value_format: "number",
          name: "operational_efficiency.stability_contributors",
          show_y_axis: true
        },
        contributors: {
          data: contributors,
          type: "line",
          value_format: "number",
          name: "operational_efficiency.contributors",
          show_y_axis: true
        },
        team_stability_contributors: {
          data: team_stability_contributors,
          stacked: true,
          type: "stacked-bar",
          value_format: "number",
          name: "operational_efficiency.team_stability_contributors",
          colors: team_colors,
          show_y_axis: true,
          height: "250"
        },
        team_contributors: {
          data: team_contributors,
          stacked: true,
          type: "stacked-bar",
          value_format: "number",
          name: "operational_efficiency.team_contributors",
          colors: team_colors,
          show_y_axis: true,
          height: "250"
        }
      }
    }
  end

  LAST_RELEASES = 6
  LAST_TIME_PERIOD = 6

  memoize def duration(last: LAST_RELEASES)
    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { {duration: _1.first.duration.seconds} }
  end

  memoize def frequency(period = :month, format = "%b", last: LAST_TIME_PERIOD)
    finished_releases(last, hotfix: true)
      .reorder("")
      .group_by_period(period, :completed_at, last: last, current: true, format:)
      .count
      .transform_values { {releases: _1} }
  end

  memoize def reldex_scores(last: 10)
    return if train.release_index.blank?

    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { {reldex: _1.first.index_score&.value} }
  end

  memoize def release_stability_contributors(last: LAST_RELEASES)
    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { _1.flat_map(&:all_commits).flat_map(&:author_email) }
      .transform_values { {contributors: _1.uniq.size} }
  end

  memoize def contributors(last: LAST_RELEASES)
    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { {contributors: _1.flat_map(&:release_changelog).compact.flat_map(&:unique_authors).size} }
  end

  memoize def team_stability_contributors(last: LAST_RELEASES)
    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { |releases| release_summary(releases[0]).team_stability_commits }
      .compact_blank
  end

  memoize def team_contributors(last: LAST_RELEASES)
    finished_releases(last)
      .group_by(&:release_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { |releases| release_summary(releases[0]).team_release_commits }
      .compact_blank
  end

  memoize def time_in_review(last: LAST_RELEASES)
    train
      .external_releases
      .includes(deployment_run: [:deployment, {step_run: {release_platform_run: [:release]}}])
      .where.not(reviewed_at: nil)
      .filter { _1.deployment_run.production_release_happened? }
      .last(last)
      .group_by(&:build_version)
      .sort_by { |v, _| v.to_semverish }.to_h
      .transform_values { _1.flat_map(&:review_time) }
      .transform_values { {time: _1.sum(&:seconds) / _1.size.to_f} }
  end

  memoize def hotfixes(last: LAST_RELEASES)
    by_version =
      finished_releases(last)
        .flat_map(&:step_runs)
        .flat_map(&:deployment_runs)
        .filter { _1.production_release_happened? }
        .group_by { _1.release.release_version }
        .sort_by { |v, _| v.to_semverish }.to_h

    by_version.transform_values do |runs|
      runs.group_by(&:platform).transform_values { |d| d.size.pred }
    end
  end

  def recovery_time
    # group by rel
    # recovery time: time between last rollout and next hotfix (line graph, across platforms)
    raise NotImplementedError
  end

  memoize def time_in_phases(last: LAST_RELEASES)
    by_version =
      finished_releases(last)
        .flat_map(&:step_runs)
        .group_by(&:release_version)
        .sort_by { |v, _| v.to_semverish }.to_h

    by_version.transform_values do |runs|
      runs.group_by(&:platform).transform_values do |by_platform|
        by_platform.group_by(&:name).transform_values do
          _1.pluck(:updated_at).max - _1.pluck(:scheduled_at).min
        end
      end
    end
  end

  # ci workflow time (per step, area graph)
  def ci_workflow_time
    raise NotImplementedError
  end

  def automations_run
    raise NotImplementedError
  end

  attr_reader :train, :organization, :team_colors

  private

  delegate :cache, to: Rails

  memoize def finished_releases(n, hotfix: false)
    releases =
      train
        .releases
        .limit(n)
        .finished
        .reorder("completed_at DESC")
        .includes(:release_changelog, {release_platform_runs: [:release_platform]}, :all_commits, step_runs: [:deployment_runs, :step])

    return releases if hotfix
    releases.release
  end

  memoize def release_summary(release)
    Queries::ReleaseSummary.new(release.id)
  end

  def cache_key
    "train/#{train.id}/devops_report"
  end

  def thaw
    cache.delete(cache_key)
  end
end
