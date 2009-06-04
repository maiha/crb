# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{crb}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["maiha"]
  s.date = %q{2009-06-05}
  s.default_executable = %q{crb}
  s.description = %q{A cucumber console that offers cucumber world enviroment on irb}
  s.email = %q{maiha@wota.jp}
  s.executables = ["crb"]
  s.extra_rdoc_files = ["README", "MIT-LICENSE"]
  s.files = ["MIT-LICENSE", "README", "Rakefile", "lib/crb.rb", "bin/crb"]
  s.homepage = %q{http://github.com/maiha/crb}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{asakusarb}
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{A cucumber console that offers cucumber world enviroment on irb}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cucumber>, [">= 0.3.9"])
      s.add_runtime_dependency(%q<webrat>, [">= 0.4.4"])
    else
      s.add_dependency(%q<cucumber>, [">= 0.3.9"])
      s.add_dependency(%q<webrat>, [">= 0.4.4"])
    end
  else
    s.add_dependency(%q<cucumber>, [">= 0.3.9"])
    s.add_dependency(%q<webrat>, [">= 0.4.4"])
  end
end
