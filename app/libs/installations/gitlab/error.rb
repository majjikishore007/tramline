module Installations
  class Gitlab::Error
    ERRORS = [
      {
        error: "invalid_token",
        decorated_exception: Installations::Gitlab::Api::TokenExpired
      }
    ]

    MESSAGES = [
      {
        message_matcher: /Another open merge request already exists for this source branch/,
        decorated_exception: Installations::Errors::PullRequestAlreadyExists
      },
      {
        message_matcher: /The merge request failed to merge/,
        decorated_exception: Installations::Errors::PullRequestNotMergeable
      },
      {
        message_matcher: /The merge request is not able to be merged/,
        decorated_exception: Installations::Errors::PullRequestNotMergeable
      },
      {
        message_matcher: /Tag (.*) already exists/,
        decorated_exception: Installations::Errors::TagReferenceAlreadyExists
      }
    ]

    def self.handle(response_body)
      new(response_body).handle
    end

    def initialize(response_body)
      @response_body = response_body
    end

    def handle
      return if match.nil?
      match[:decorated_exception].new
    end

    private

    attr_reader :response_body
    alias_method :body, :response_body

    def match
      @match ||= matched_error || matched_message
    end

    def matched_message
      MESSAGES.find { |known_error_message| known_error_message[:message_matcher] =~ message }
    end

    def matched_error
      ERRORS.find { |known_error| known_error[:error].eql?(error) }
    end

    def error
      body["error"]
    end

    def message
      [*body["message"]].first
    end
  end
end