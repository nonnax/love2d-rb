#!/usr/bin/env ruby
# Id$ nonnax Wed Jan 17 11:15:05 2024
# https://github.com/nonnax
# calculation.rb

module Calculation
  HALF_PI = Math::PI / 2
  TWO_PI = 2 * Math::PI

  def dist(x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    Math.sqrt(dx**2 + dy**2)
  end

  def dist_sq(x1, y1, x2, y2)
    dx = x2 - x1
    dy = y2 - y1
    dx**2 + dy**2
  end

  def radians(degrees)
    degrees * (Math::PI / 180)
  end

  def degrees(radians)
    radians * (180 / Math::PI)
  end

  def sq(n)
    n**2
  end

  # functional style of clamp
  def constrain(n, low, high)
    [low, [n, high].min].max
  end
  alias clamp constrain

  # functional style of clamp
  def fconstrain(low, high)
    ->(n){ [low, [n, high].min].max }
  end

  def map(value, start1, stop1, start2, stop2)
    start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1).to_f)
  end

  # define a mapping function range1 -> range2
  # returns a lambda f(x)
  def fmap(start1, stop1, start2, stop2)
    ->(value) do
      start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1).to_f)
    end
  end

  # unit scaling
  def norm(value, start, stop)
    (value - start) / (stop - start)
  end

  def lerp(start, stop, amt)
    start + (stop - start) * amt
  end

  def mag(x, y)
    Math.sqrt(x**2 + y**2)
  end

  def mag_sq(x, y)
    x**2 + y**2
  end

  def random(*args)
    if args.empty?
      rand
    elsif args.length == 1
      rand(args[0])
    elsif args.length == 2
      rand(args[0]..args[1])
    else
      raise ArgumentError, "Invalid number of arguments for random function."
    end
  end

  def random_seed(seed)
    srand(seed)
  end

  def noise(*args)
    # Implement noise function if needed
    # Placeholder for now
    rand
  end
end

if __FILE__==$0
  # Example usage
  Kernel.include Calculation

  puts "Distance: #{dist(0, 0, 3, 4)}"
  puts "Radians: #{radians(180)}"
  puts "Constrained: #{constrain(25, 10, 20)}"
  puts "Clamped: #{clamp(25, 10, 20)}"
  puts "Mapped: #{map(5, 0, 10, 0, 100)}"
  currymap=fmap(0, 10, 0, 100)
  puts "Mapped: #{currymap.call(2)}"

  puts "Random: #{random(10)}"
  puts "Noise: #{noise()}"


  p a=[1123, 423,1243, 2].map(&method(:radians))

  p a=[1123, 423,1243, 2].map(&fmap(0, 2000, 0, 100))

  p a=[1123, 423,1243, 2].map(&fconstrain(100, 1000))
end
