class AppearedIn
  include Neo4j::ActiveRel

  from_class :any
  to_class :any

  type 'appeared_in'
  property :frequency, type: Integer

  validates_presence_of :frequency

  def add(count)
  	self.frequency = self.frequency + count
  end
end