if Rails.env.production?
  if ENV.fetch('APPLICATION_ENV','production') == 'production'
    ActiveStorage::Blob.service = ActiveStorage::Service.configure(
      :amazon,
      Rails.application.credentials.dig(:aws, :production, :activestorage)
    )
  else
    ActiveStorage::Blob.service = ActiveStorage::Service.configure(
      :amazon,
      Rails.application.credentials.dig(:aws, :staging, :activestorage)
    )
  end
end
