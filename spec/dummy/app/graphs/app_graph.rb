class AppGraph < Onsi::Graph::Model
  add_version(Onsi::Graph::Version.new('2019-07-01', 'Person'))

  set_callback(:action, :before, :authenticate!)

  private

  def authenticate!
    # raise Onsi::Graph::Abort.new(401, {}, nil)
  end
end
