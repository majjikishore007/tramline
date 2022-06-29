class IntegrationListeners::GithubController < IntegrationListenerController
  skip_before_action :verify_authenticity_token, only: [:events]
  skip_before_action :require_login, only: [:events]

  delegate :transaction, to: ActiveRecord::Base
  delegate :current_run, to: :train

  def providable_params
    super.merge(installation_id:)
  end

  def events
    case event_type
    when 'workflow_run'
      handle_workflow_run
    when 'push'
      handle_push
    when 'ping'
      handle_ping
    end
  end

  def handle_ping
    head :accepted
  end

  def handle_push
    response = WebhookHandlers::Github::Push.process(train, params)
    head response.status
  end

  def handle_workflow_run
    response = WebhookHandlers::Github::WorkflowRun.process(train, params)
    head response.status
  end

  private

  def event_type
    request.headers['HTTP_X_GITHUB_EVENT']
  end

  def train
    @train ||= Releases::Train.find_by(id: params[:train_id])
  end
end