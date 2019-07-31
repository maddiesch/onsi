class AppGraph < Onsi::Graph::Model
  Onsi::Graph::Permissions.add_named_permissions(:allow_all, AppGraph[2019, 7, 1]::Permissions::AllowAll)

  add_version(
    Onsi::Graph::Version.new(
      '2019-07-01',
      Onsi::Graph::Version::Root.new('Person', ->(_) { Person.current })
    )
  )

  set_callback(:action, :before, :authenticate!)

  private

  def authenticate!
    Person.current = Person.first

    raise Onsi::Graph::Abort.new(401, {}, nil) unless Person.current.present?
  end
end
