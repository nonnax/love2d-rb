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

  #destructive version
  def add!(other)
    set! self + other
  end
  def mult!(scalar)
    set! self * scalar
  end
  def sub!(other)
    set! self - other
  end
  def div!(scalar)
    set! self / scalar
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
  alias angle_to angle2

  # Returns the euclidean distance between this vector and +other_vector+.
  def distance(b)
    dx = x - b.x
    dy = y - b.y
    Math.sqrt(dx ** 2 + dy ** 2)
  end
  alias dist distance

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
    set! Vec[cos * x - sin * y, sin * x + cos * y]
  end

  def self.polar(theta, r = 1)
    Vec[Math.cos(theta)*r, Math.sin(theta)*r]
  end

  # --- Get the perpendicular projection vector of vector b.
  def project(b)
    b.norm * self.dot(b.clone.norm)
  end

  # --- Get the perpendicular vector of a vector.
  # --  param vector v to get perpendicular axes from
  def perpendicular(v)
  	Vec[-v.y, v.x]
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
  alias limit! limit

  # make 3D
  def coerce(z)
    [self, z]
  end

  def inspect
    "Vector(#{x},#{y})"
  end

end


