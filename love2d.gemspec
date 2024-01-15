
Gem::Specification.new do |s|
  s.name = 'love2d'
  s.version = '0.0.1'
  s.date = '2024-01-15'
  s.summary = "love2d"
  s.authors = ["xxanon"]
  s.email = "ironald@gmail.com"
  s.files = `git ls-files`.split("\n") - %w[bin misc]
  s.executables += `git ls-files bin`.split("\n").map{|e| File.basename(e)}
  s.homepage = "https://github.com/nonnax/love2d.git"
  s.license = "MIT"
end

