class AppGraph[2019, 7, 1]::Edges::EmailMessages < Onsi::Graph::Edge
  from AppGraph[2019, 7, 1]::Nodes::Email
  to AppGraph[2019, 7, 1]::Nodes::Message

  association do
    tail.model.messages
  end
end
