class Ability
  include CanCan::Ability
  def initialize(employee)
    if employee.admin?
        can :manage, :all
    elsif employee.manager?
        can :read, Project do |project|
            project.try(:employee) == employee
        end
        can :read, Employee do |emp|
            emp.try(:manager) == employee
        end
    end
  end
end
