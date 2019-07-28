class AppGraph[2019, 7, 1]::Permissions::AllowAll < Onsi::Graph::Permissions
  def can_read?
    true
  end

  def can_create?
    true
  end

  def can_update?
    true
  end

  def can_destroy?
    true
  end
end
