Gem::Specification.new do |gem|
  gem.name = 'source_map'
  gem.version = '3.0.1'

  gem.summary = 'Ruby support for source_maps'
  gem.description = <<-DESC
https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit
  DESC

  gem.authors = ['Conrad Irwin']
  gem.email = %w(conrad.irwin@gmail.com)
  gem.homepage = 'http://github.com/ConradIrwin/source_map'

  gem.license = 'BSD'

  gem.required_ruby_version = '>= 1.8.7'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'

  gem.files = Dir[*%w(
      lib/*
      lib/*/*
      LICENSE*
      README*)]
end
