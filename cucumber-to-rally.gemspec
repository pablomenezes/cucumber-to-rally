Gem::Specification.new do |s|
	s.name			= "cucumber-to-rally"
	s.version		= "0.1.3"
	s.description	= "A gem to make a bridge between Rally and Cucumber Steps"
	s.summary		= "Version 0.1.3"
	s.author		= "Pablo Menezes"
	s.add_dependency 'rally_rest_api','>= 1.0.3'
	s.add_dependency 'logger','>= 1.2.8'
	s.add_dependency 'activeresource', '2.3.4'
	s.files			= Dir["{lib/**/*.rb,README.rdoc,*.gemspec}"]
end
