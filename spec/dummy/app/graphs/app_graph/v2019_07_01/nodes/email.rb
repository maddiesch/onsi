class AppGraph[2019, 7, 1]::Nodes::Email < Onsi::Graph::Node
  model ::Email

  permissions :allow_all

  assign_attr :address
end
