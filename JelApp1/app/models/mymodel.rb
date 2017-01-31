class Mymodel < ApplicationRecord
	establish_connection "mysql2://root:a@localhost/jel"
end
