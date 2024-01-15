Vec =
Struct.new(:x, :y) do
  include Comparable

  def set!(other)
    self.x = other.x
    self.y = other.y
    self
  end

  def +(other)
    Vec[x + other.x, y + other.y]
  end

  def -(other)
    Vec[x - other.x, y - other.y]
  end

  def *(scalar)
    Vec[x * scalar, y * scalar]
  end

  def /(scalar)
    Vec[x / scalar, y / scalar]
  end

  def -@
    Vec[-x, -y]
  end

  def clone
    Vec[x, y]
  end

  def norm
    Vec[x/mag ,y/mag]
  end

  def norm!
    set! norm
  end

  def mag
    Math.sqrt(x*x + y*y)
  end

  def mag2
    x*x + y*y
  end

  def mag=(len)
    set! norm*len
  end

  # The dot product is commutative. dot(a,b) == dot(b,a).
  def dot(v)
    x * v.x + y * v.y
  end

  def <=>(other)
    return unless other.is_a?(self.class)
    x <=> other.x && y <=> other.y
  end

  def heading
    Math.atan2(y, x)
  end

  def angle2(b)
    a = Math.atan2(y, x) - Math.atan2(b.y, b.x)
    (a + Math::PI) % (Math::PI*2) - Math::PI
  end

  # Returns the euclidean distance between this vector and +other_vector+.
  def distance(b)
    dx = x - b.x
    dy = y - b.y
    Math.sqrt(dx ** 2 + dy ** 2)
  end

  # Returns a vector corresponding to the rotation of this vector around the
  # origin (0, 0) by +radians+ radians.
  def rotate(radians)
    sin = Math.sin radians
    cos = Math.cos radians
    Vec[ cos * x - sin * y, sin * x + cos * y]
  end

  # Rotates this vector by +radians+ radians around the origin (0, 0).
  def rotate!(radians)
    sin = Math.sin radians
    cos = Math.cos radians
    prev_x = x
    x = cos * x - sin * y
    y = sin * prev_x + cos * y
    set! Vec[x, y]
  end

  def polar(theta, r = 1)
    Vec[Math.cos(theta)*r, Math.sin(theta)*r]
  end

  def project(b)
    b.norm * self.dot(b.clone.norm)
  end

  # def projectTo(b)
  #   (self*b/b.mag2)*b
  # end

  def limit(max)
    m = mag()
    if m > max
      x = (self / m) * max
      set! x
    else
      self
    end

  end

  # make 3D
  def coerce(z)
    [self, z]
  end

  def inspect
    "Vector(#{x},#{y})"
  end

end


