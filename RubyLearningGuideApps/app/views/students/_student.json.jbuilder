json.extract! student, :id, :name, :blood_group, :dept, :created_at, :updated_at
json.url student_url(student, format: :json)