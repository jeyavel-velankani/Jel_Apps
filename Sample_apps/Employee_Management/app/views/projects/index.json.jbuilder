json.array!(@projects) do |project|
  json.extract! project, :id, :name, :customer, :description, :price, :employee_id
  json.url project_url(project, format: :json)
end
