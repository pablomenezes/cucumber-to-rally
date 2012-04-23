require 'test/unit'
require 'cucumberToRally'

class CucumberTest < Test::Unit::TestCase
	def testInitialize
		assert_equal "Iniciando...", CucumberToRally.say
	end
end
