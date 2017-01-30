r1 = Role.create({name: "Staff", description: "Can read and update his details"})
r2 = Role.create({name: "Manager", description: "Can read details of staff and project under him"})
r3 = Role.create({name: "Admin", description: "Can perform any CRUD operation on any resource"})


e2 = Employee.create({name: "Sue", email: "sue@example.com", password: "aaaaaaaa", password_confirmation: "aaaaaaaa", role_id: r2.id})
e3 = Employee.create({name: "Kev", email: "kev@example.com", password: "aaaaaaaa", password_confirmation: "aaaaaaaa", role_id: r2.id})
e4 = Employee.create({name: "Jack", email: "jack@example.com", password: "aaaaaaaa", password_confirmation: "aaaaaaaa", role_id: r3.id})
e1 = Employee.create({name: "Sally", email: "sally@example.com", password: "aaaaaaaa", password_confirmation: "aaaaaaaa", role_id: r1.id, manager_id:e2.id})

p1 = Project.create({name: "Rayban Sunglasses", customer: "abc", description: "Stylish shades", price: 99.99, employee_id: e2.id})
p2 = Project.create({name: "Gucci watch", customer: "abc", description: "Expensive timepiece", price: 199.99, employee_id: e2.id})
p3 = Project.create({name: "Henri Lloyd Pullover", customer: "abc", description: "Classy knitwear", price: 299.99, employee_id: e3.id})
p4 = Project.create({name: "Porsche socks", customer: "abc", description: "Cosy footwear", price: 399.99, employee_id: e3.id})