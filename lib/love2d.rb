['love.rb',
'camera.rb',
'p5Vector.rb',
'range.rb',
'shapes.rb',
'vector.rb',
].map{|l|
 require ['love2d', l].join('/')
}
