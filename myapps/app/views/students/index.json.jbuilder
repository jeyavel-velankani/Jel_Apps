json.array!(@students) do |student|
  json.extract! student, :id, :name, :age, :city
  json.url student_url(student, format: :json)
end
