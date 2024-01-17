# Draws an unfilled circle with a line of any thickness
# Based on code by shawn42
#
# TODO:
# * Textures(?)
# * Use OpenGL (e.g. triangle fan)
# * Convert to C++ (and submit pull request)
# * Anti-aliasing based on VASEr's techniques (http://tyt2y3.github.io/vaser-web/)

require 'gosu'
# require 'opengl'

module ZOrder BACKGROUND, MIDDLE, TOP = *0..2 end

def Math.random(a, b)
  Gosu::random(a, b)
end

def Math.box_center(x1, y1, w, h)
    [(x1 + w) / 2, (y1 + h) / 2]
end

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def inc(n=1)
    self + n
  end
  def dec(n=1)
    self - n
  end
end

module Gosu
  class Color
    CHARCOAL  = Gosu::Color.argb(0xff36454f)
    LIGHTGRAY = Gosu::Color.argb(0xffd3d3d3)
    DARKGRAY  = Gosu::Color.argb(0xffa9a9a9)
    SILVER    = Gosu::Color.argb(0xffc0c0c0)
    MAGENTA = FUCHSIA
  end
  def self.xxdraw_circle(x, y, r, c, z = 0, thickness = 1, sides = nil, mode = :default)
    # Unless specified, calculate a nice-looking "minimum" number of sides
    # sides = (r + Math::sqrt(r * 0.1) * 4).floor if sides.nil?
    sides = (2.0 * r * Math::PI).floor if sides.nil?

    # Calculate the inner and outer offsets from the "true" circle
    offs = thickness * 0.5
    r_in = r - offs
    r_out = r + offs

    # Calculate the angular increment
    ai = 360.0 / sides.to_f

    translate(x, y) {
      ang = 0
      while ang <= 359.9 do
        draw_quad(
          Gosu.offset_x(ang, r_in), Gosu.offset_y(ang, r_in), c,
          Gosu.offset_x(ang, r_out), Gosu.offset_y(ang, r_out), c,
          Gosu.offset_x(ang + ai, r_in), Gosu.offset_y(ang + ai, r_in), c,
          Gosu.offset_x(ang + ai, r_out), Gosu.offset_y(ang + ai, r_out), c,
          z, mode
        )
        ang += ai
      end
    }
  end

  def self.radians(degrees)
    # degrees * Math::PI / 180
    Gosu.degrees_to_radians(degrees)
  end

  def self.draw_circle(x, y, radius, color, *)
    segments = 30 # Increase for a smoother circle

    angle_increment = 360.0 / segments

    # Draw the filled circle using a series of lines
    segments.times do |i|
      angle1 = Gosu.angle(0, 0, 1, 0) + i * angle_increment
      angle2 = Gosu.angle(0, 0, 1, 0) + (i + 1) * angle_increment

      x1 = x + radius * Math.cos(Gosu.radians(angle1))
      y1 = y + radius * Math.sin(Gosu.radians(angle1))
      x2 = x + radius * Math.cos(Gosu.radians(angle2))
      y2 = y + radius * Math.sin(Gosu.radians(angle2))

      draw_line(x1, y1, color, x2, y2, color, z = 0)
    end
  end

  class Window
  # draw_rot(x, y, z = 0, angle = 0, center_x = 0.5, center_y = 0.5, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
    def circle(x, y, r, color=Gosu::Color::WHITE, type:'default', angle: 0, z:0, thickness:1, sides: nil, mode: :default, scale_x: 1, scale_y: 1)
      if type=='fill'
        c = Gosu::Image.new(Circle.new(r))
        c.draw_rot x, y, z, angle, center_x = 0.5, center_y = 0.5, scale_x, scale_y, color
      else
        Gosu::draw_circle(x, y, r, color, z, thickness, sides, mode)
      end
    end

    alias draw_circle circle

    def line(ax, ay, bx, by, color=Gosu::Color::RED)
        draw_line(ax, ay, color, bx, by, color)
    end
    # draw_rect(x, y, width, height, c, z = 0, mode = :default)
    def rect(x, y, h, w, color=Gosu::Color::WHITE, z:0, center:false)
        x -= w/2.0 if center
        draw_rect(x, y, h, w, color, z)
    end

    # draw_triangle(x1, y1, c1, x2, y2, c2, x3, y3, c3, z = 0, mode = :default) ⇒ void
    def triangle(ax, ay, bx, by, cx, cy, color=Gosu::Color::WHITE, z: 0, mode: :default)
        draw_triangle(ax, ay, color, bx, by, color, cx, cy, color, z, mode)
    end

    def print(text, x, y, color=Gosu::Color::WHITE, size:10, z:ZOrder::TOP)
      @font.draw_text(text, x, y, z, 1.0, 1.0, color)
    end

    def dt()= (update_interval / 1000.0)

    def on_update(dt)
    end

    def update
      # super
      on_update(update_interval / 1000.0)
    end

  end # Window class

end # Gosu module


#Circle parameter - Radius
#Image draw parameters - x, y, z, horizontal scale (use for ovals), vertical scale (use for ovals), colour
#Colour - use Gosu::Image::{Colour name} or .rgb({red},{green},{blue}) or .rgba({alpha}{red},{green},{blue},)
#Note - alpha is used for transparency.
#drawn as an elipse (0.5 width:)

class Circle
  attr_reader :columns, :rows

  def initialize(radius)
    @columns = @rows = radius * 2

    clear, solid = 0x00.chr, 0xff.chr

    lower_half = (0...radius).map do |y|
      x = Math.sqrt(radius ** 2 - y ** 2).round
      right_half = "#{solid * x}#{clear * (radius - x)}"
      right_half.reverse + right_half
    end.join
    alpha_channel = lower_half.reverse + lower_half
    #Expand alpha bytes into RGBA color values.
    @blob = alpha_channel.gsub(/./) { |alpha| solid * 3 + alpha }
  end

  def to_blob
    @blob
  end
end

class Shape
  # draw_rot(x, y, z = 0, angle = 0, center_x = 0.5, center_y = 0.5, scale_x = 1, scale_y = 1, color = 0xff_ffffff, mode = :default) ⇒ void
  def self.circle(x, y, r=1)
    c = Gosu::Image.new(Circle.new(r))
    c.draw_rot x, y, 0
  end
  def self.ellipse(x, y, w=1, h=1, color=Gosu::Color::GREEN, zorder=ZOrder::BACKGROUND)
    c=Gosu::Image.new(Circle.new(w))
    c.draw(x, y, zorder, w, h, color)
  end
end

class Gosu::Win < Gosu::Window
  SCREEN_HEIGHT = 600
  SCREEN_WIDTH = 800
  INITIAL_ZOOM = 1.0
  ZOOM_STEP = 0.1
  attr_accessor :planets
  def initialize(w=SCREEN_WIDTH, h=SCREEN_HEIGHT, z=false)
    super(w, h, z)
    @font = Gosu::Font.new(9)
    @zoom = INITIAL_ZOOM
  end
end


Color = Gosu::Color

# update_interval (both the constructor argument, and the r/w property) controls the target framerate of Gosu.
# However, because Gosu usually waits for a vsync each frame, higher values than 60 (or whatever your screen uses) don't work.
#
# The vsync part is actually becoming a bit of an issue. When I first wrote Gosu, CRT screens started being replaced by TFT flatscreens
# which all had a 60 Hz refresh rate, and I hoped that 60 Hz would be *the* standard framerate for a long time.
# But I've now received issue reports on GitHub from users with 40 Hz(!) laptop screens, and many desktop screens
# are running at 75 Hz all the way up to 144 Hz. And some unlucky people probably run their computer at 30 Hz because
# their HDMI cable can't do 4K at 60 Hz etc... Gosu's model of always running at 60 FPS is sadly not flexible enough for the reality of today's screens.
#
# If you want to work with delta time, I suggest you use a really small value for update_interval, maybe 5, so that Gosu will max out the screen's Hz if possible.
# And then you measure the frame length yourself using Gosu.milliseconds (from one update call to the next), and move your objects accordingly.
