

task default: %w[build]

desc "Bundle install dependencies"
task :bundle do
  sh "bundle install"
end

desc "Build the love2d.gem file"
task :build do
  sh "gem build love2d.gemspec"
end

desc "install love2d-x.x.x.gem"
task install: %w[build] do
  sh "gem install $(ls love2d-*.gem)"
end
