class Vec
  include Comparable
  attr_accessor :x, :y

  instance_eval do
    alias [] new
  end

  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  def set!(other)
    @x = other.x
    @y = other.y
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

  def angle_to(b)
    a = Math.atan2(y, x) - Math.atan2(b.y, b.x)
    (a + Math::PI) % (Math::PI*2) - Math::PI
  end
  alias angle2 angle_to

  def angle_between(v)
    # dot_product = @x * v.x + @y * v.y
    Math.acos(dot(v) / (mag() * v.mag()))
  end

  def degrees
     self.class.to_degrees_gosu(heading)
  end

  def degrees_to(b)
     self.class.to_degrees_gosu(angle2(b))
  end
  alias degrees2 degrees_to

  def self.to_degrees_gosu(theta)
   theta * 180.0 / Math::PI + 90
  end

  def angle360(b)
    dot = x*b.x + y*b.y      # dot product
    det = x*b.y - y*b.x      # determinant
    Math.atan2(det, dot)  # atan2(y, x) or atan2(sin, cos)
  end

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
  alias tangent perpendicular

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


