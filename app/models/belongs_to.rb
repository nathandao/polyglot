class BelongsTo
  include Neo4j::ActiveRel

  from_class :any
  to_class :any

  type 'belongs_to'

  validates_presence_of :frequency

  def add(count)
    self.frequency = self.frequency + count
  end

end
