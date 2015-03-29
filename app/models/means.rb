class Means
  include Neo4j::ActiveRel

  from_class :any
  to_class :any

  type 'means'

end
