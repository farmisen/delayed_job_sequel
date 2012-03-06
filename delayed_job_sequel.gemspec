# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name              = 'delayed_job_sequel'
  s.summary           = 'Sequel backend for delayed_job'
  s.version           = '0.2.0'
  s.authors           = 'Fabrice Armisen'
  s.date              = Date.today.to_s
  s.email             = 'farmisen@gmail.com'
  s.extra_rdoc_files  = ["LICENSE", "README.md"]
  s.files             = Dir.glob("{lib,spec}/**/*") + %w[LICENSE README.md]
  s.homepage          = 'http://github.com/farmisen/delayed_job_sequel'
  s.rdoc_options      = ['--charset=UTF-8']
  s.require_paths     = ['lib']
  s.test_files        = Dir.glob('spec/**/*')

  s.add_runtime_dependency      'sequel'
  s.add_runtime_dependency      'activesupport','>= 3.0.0'
  s.add_runtime_dependency      'i18n'
  s.add_runtime_dependency      'delayed_job',  '> 2.1'
  s.add_development_dependency  'sqlite3-ruby', '= 1.2.5'
  s.add_development_dependency  'rspec',        '>= 2.1.0'
  s.add_development_dependency  'rake'
end
