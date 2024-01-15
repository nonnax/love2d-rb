#!/usr/bin/env ruby
# Id$ nonnax Fri Jan 12 10:45:31 2024
# https://github.com/nonnax

# vector2d.rb

class Vector2D
  attr_accessor :x, :y

  instance_eval do
    alias [] new
  end

  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  def mag
    Math.sqrt(@x**2 + @y**2)
  end

  def mag2
    @x**2 + @y**2
  end

  def add(v)
    @x += v.x
    @y += v.y
    self
  end

  def sub(v)
    @x -= v.x
    @y -= v.y
    self
  end

  def mult(n)
    @x *= n
    @y *= n
    self
  end

  def div(n)
    @x /= n
    @y /= n
    self
  end

  def clone()
    Vector2D[@x, @x]
  end

  def normalize
    mag = mag()
    div(mag) unless mag.zero?
    self
  end
  alias norm normalize

  def limit(max)
    mag2 = mag2()
    if mag2 > max**2
      div(Math.sqrt(mag2))
      mult(max)
    end
    self
  end

  def mag= (n)
    normalize
    mult(n)
  end

  def dist(v)
    Math.sqrt((@x - v.x)**2 + (@y - v.y)**2)
  end

  def angle_between(v)
    dot_product = @x * v.x + @y * v.y
    Math.acos(dot_product / (mag() * v.mag()))
  end

  def dot(v)
    @x * v.x + @y * v.y
  end

  def lerp(v, amt)
    x = @x + (v.x - @x) * amt
    y = @y + (v.y - @y) * amt
    Vector2D.new(x, y)
  end

  def self.random
    angle = rand * (2 * Math::PI)
    Vector2D.new(Math.cos(angle), Math.sin(angle))
  end

  def project(b)
    bcopy = b.clone.norm
    bcopy * dot(bcopy)
  end

  include Comparable

  def set!(other)
    @x = other.x
    @y = other.y
    self
  end

  def +(other)
    Vector2D[@x + other.x, @y + other.y]
  end

  def -(other)
    Vector2D[@x - other.x, @y - other.y]
  end

  def *(scalar)
    Vector2D[@x * scalar, @y * scalar]
  end

  def -@
    Vector2D[-@x, -@y]
  end

  def to_s()
    "#{self.class.name}#{[@x, @y].inspect}"
  end

  def <=>(other)
    return unless other.is_a?(self.class)
    self.x <=> other.x && self.y <=> other.y
  end

end


# vector.rb

class Vector3D
  attr_accessor :x, :y, :z

  instance_eval do
    alias [] new
  end

  def initialize(x = 0, y = 0, z = 0)
    @x = x
    @y = y
    @z = z
  end

  def mag
    Math.sqrt(@x**2 + @y**2 + @z**2)
  end

  def mag2
    @x**2 + @y**2 + @z**2
  end

  def add(v)
    @x += v.x
    @y += v.y
    @z += v.z
    self
  end

  def sub(v)
    @x -= v.x
    @y -= v.y
    @z -= v.z
    self
  end

  def mult(n)
    @x *= n
    @y *= n
    @z *= n
    self
  end

  def div(n)
    @x /= n
    @y /= n
    @z /= n
    self
  end

  def normalize
    mag = mag()
    div(mag) unless mag.zero?
    self
  end

  def mag= (n)
    normalize
    mult(n)
  end

  def limit(max)
    mag2 = mag2()
    if mag2 > max**2
      div(Math.sqrt(mag2))
      mult(max)
    end
    self
  end

  def to_s()
    "#{self.class.name}#{[@x, @y, @z].compact.inspect}"
  end

  def dist(v)
    Math.sqrt((@x - v.x)**2 + (@y - v.y)**2 + (@z - v.z)**2)
  end

  def angle_between(v)
    # dot_product = @x * v.x + @y * v.y + @z * v.z
    Math.acos(dot(v) / (mag() * v.mag()))
  end

  def heading
    Math.atan2(@y, @x)
  end

  def dot(v)
    @x * v.x + @y * v.y + @z * v.z
  end

  def cross(v)
    x = @y * v.z - @z * v.y
    y = @z * v.x - @x * v.z
    z = @x * v.y - @y * v.x
    Vector3D.new(x, y, z)
  end

  def lerp(v, amt)
    x = @x + (v.x - @x) * amt
    y = @y + (v.y - @y) * amt
    z = @z + (v.z - @z) * amt
    Vector3D.new(x, y, z)
  end

  def self.random_2d
    angle = rand * (2 * Math::PI)
    Vector3D.new(Math.cos(angle), Math.sin(angle))
  end

  def self.random_3d
    angle1 = rand * (2 * Math::PI)
    angle2 = rand * (2 * Math::PI)
    x = Math.sin(angle1) * Math.cos(angle2)
    y = Math.sin(angle1) * Math.sin(angle2)
    z = Math.cos(angle1)
    Vector3D.new(x, y, z)
  end
end

# Example usage
# v1 = Vector2D[3, 4]
# v2 = Vector2D[1, 2]
#
# puts "Distance between v1 and v2: #{v1.dist(v2)}"
# puts "Angle between v1 and v2: #{v1.angle_between(v2)}"
# puts "Dot product of v1 and v2: #{v1.dot(v2)}"
#
# lerp_vector = v1.lerp(v2, 0.5)
# puts "Linear interpolation between v1 and v2: #{lerp_vector}"
#
# random_2d = Vector2D.random
# puts "Random 2D Vector: #{random_2d}"
#
# randomB = Vector2D.random
# puts "Random 2D B Vector: #{randomB}"
# puts "Setmag: #{randomB.mag = 200 }"
# puts "Updated: #{randomB}"
# puts "Addition: #{randomB+random_2d}"
#
#
# # Example usage
# v1 = Vector3D[3, 4, 5]
# v2 = Vector3D[1, 2, 3]
#
# puts "Distance between v1 and v2: #{v1.dist(v2)}"
# puts "Angle between v1 and v2: #{v1.angle_between(v2)}"
# puts "Dot product of v1 and v2: #{v1.dot(v2)}"
#
# cross_product = v1.cross(v2)
# puts "Cross product of v1 and v2: #{cross_product}"
#
# lerp_vector = v1.lerp(v2, 0.5)
# puts "Linear interpolation between v1 and v2: #{lerp_vector}"
#
# random_2d = Vector3D.random_2d
# puts "Random 2D Vector: #{random_2d}"
#
# random_3d = Vector3D.random_3d
# puts "Random 3D Vector: #{random_3d}"
# puts "Setmag: #{random_3d.mag = 200 }"
# puts "Updated: #{random_3d}"
