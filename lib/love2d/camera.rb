#!/usr/bin/env ruby
# Id$ nonnax Tue Jan 16 22:46:08 2024
# https://github.com/nonnax

require 'gosu'

class Camera
  attr_accessor :x, :y, :zoom

  def initialize(window)
    @window = window
    @x = 0
    @y = 0
    @zoom = 1.0
  end

  def attach(obj)
    @target = obj
  end

  def detach
    @target = nil
  end

  def look_at(x, y)
    @x = x - @window.width / 2
    @y = y - @window.height / 2
  end

  def update
    if @target
      @x = @target.x - @window.width / 2
      @y = @target.y - @window.height / 2
    end
  end

  def apply
    Gosu.translate(-@x, -@y) do
      Gosu.scale(@zoom, @zoom, @x + @window.width / 2, @y + @window.height / 2) do
        yield
      end
    end
  end
end
