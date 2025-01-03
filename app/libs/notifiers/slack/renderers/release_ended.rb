module Notifiers
  module Slack
    class Renderers::ReleaseEnded < Renderers::Base
      include ActionView::Helpers::DateHelper

      TEMPLATE_FILE = "release_ended.json.erb".freeze

      def total_run_time
        return "N/A" if @release_completed_at.blank? || @release_started_at.blank?
        distance_of_time_in_words(@release_started_at, @release_completed_at)
      end
    end
  end
end
