class Integrations::CrashlyticsController < IntegrationsController
  def integration_params
    params.require(:integration)
      .permit(
        :category,
        providable: [:project_number, :json_key_file, :type]
      ).merge(current_user:)
  end

  def providable_params
    super
      .merge(json_key: json_key_file.read)
      .merge(integration_params[:providable].slice(:project_number))
  end

  def providable_params_errors
    @providable_params_errors ||= Validators::KeyFileValidator.validate(json_key_file).errors
  end

  def json_key_file
    @json_key_file ||= integration_params[:providable][:json_key_file]
  end

  def set_providable_params
    if providable_params_errors.present?
      flash.now[:error] = providable_params_errors.first
      set_integrations_by_categories
      set_app_config_tabs
      render :index, status: :unprocessable_entity
    else
      super
    end
  end
end
