#!/usr/bin/env ruby
# Id$ nonnax Thu Jan 11 21:08:25 2024
# https://github.com/nonnax
require "gosu"

# module ZOrder BACKGROUND, MIDDLE, TOP = *0..2 end

# NONE    = Gosu::Color.argb(0x00000000)
# BLACK   = Gosu::Color.argb(0xff000000)
# GRAY    = Gosu::Color.argb(0xff808080)
# WHITE   = Gosu::Color.argb(0xffffffff)
# AQUA    = Gosu::Color.argb(0xff00ffff)
# RED     = Gosu::Color.argb(0xffff0000)
# GREEN   = Gosu::Color.argb(0xff00ff00)
# BLUE    = Gosu::Color.argb(0xff0000ff)
# YELLOW  = Gosu::Color.argb(0xffffff00)
# FUCHSIA = Gosu::Color.argb(0xffff00ff)
# CYAN    = Gosu::Color.argb(0xff00ffff)
# CHARCOAL  = Gosu::Color.argb(0xff36454f)
# LIGHTGRAY = Gosu::Color.argb(0xffd3d3d3)
# GRAY      = Gosu::Color.argb(0xff808080)
# DARKGRAY  = Gosu::Color.argb(0xffa9a9a9)
# SILVER    = Gosu::Color.argb(0xffc0c0c0)

# Charcoal	#36454F	rgb(54, 69, 79)
# Light Gray	#D3D3D3	rgb(211, 211, 211)
# Gray	#808080	rgb(128, 128, 128)
# Dark Gray	#A9A9A9	rgb(169, 169, 169)
# Silver	#C0C0C0	rgb(192, 192, 192)
# Slate Gray	#708090	rgb(112, 128, 144)
# Smoke	#848884	rgb(132, 136, 132)
# Steel Gray	#71797E	rgb(113, 121, 126)

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
  def self.circle(x, y, r=1)
    c = Gosu::Image.new(Circle.new(r))
    c.draw_rot x, y, 0
  end
  def self.ellipse(x, y, w=1, h=1, color=Gosu::Color::GREEN, zorder=ZOrder::BACKGROUND)
    c=Gosu::Image.new(Circle.new(w))
    c.draw(x, y, zorder, w, h, color)
  end
  def self.line(ax, ay, bx, by, color=Gosu::Color::WHITE)
    Gosu::draw_line(ax, ay, color, bx, by, color)
  end
end

class BoundingBox
  attr_reader :left, :bottom, :width, :height, :right, :top

  def initialize(left, bottom, width, height)
    @left = left
    @bottom = bottom
    @width = width
    @height = height
    @right = @left + @width
    @top = @bottom + @height
  end

  def collide?(x, y)
    x >= left && x <= right && y >= bottom && y <= top
  end

  def intersects?(box)
    self.right > box.left && self.bottom < box.top && self.left < box.right &&
self.top > box.bottom
  end

  def on_collide(x, y, &block)
    block.call if collide?(x, y)
  end

  def on_intersect(box, &block)
    block.call if intersects?(box)
  end
end
