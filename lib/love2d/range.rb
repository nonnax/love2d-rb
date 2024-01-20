#!/usr/bin/env ruby
# Id$ nonnax Thu Jan 11 21:08:25 2024
# https://github.com/nonnax

class Range

  #
  # Linearly interpolates a value between begin and end.
  #
  def interpolate(t)
    # TODO possibly allow geometric or arbitrary interpolation
    a,  b  = self.begin, self.end
    ta, tb = (1.0 - t), t
    a * ta  + b * tb
  end

 def fmap(range_target)
   ->(x){ (range_target.min+(range_target.max-range_target.min)) * ((x-self.min)/(self.max-self.min).to_f)}
 end
end
