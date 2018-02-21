json.extract! note, :id, :content, :created_at, :updated_at
json.reason do
  if note.reason.present?
    json.extract! note.reason, :id, :name
  end
end
json.lead_action do
  if note.lead_action.present?
    json.extract! note.lead_action, :id, :name
  end
end
json.user do
  if note.user.present?
    json.extract! note.user, :id, :name
  end
end
json.url note_url(note, format: :json)
json.web_url note_url(note, format: :html)