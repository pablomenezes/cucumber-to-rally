$VERBOSE = nil

require 'rubygems'
require 'active_resource'
require 'logger'
require 'rally_rest_api'
require 'date'
require 'time'
require 'cucumber'
require 'fileutils'

CONTENT = '# -*- encoding : utf-8 -*-


# => The function createTestCase, used in this example, don\'t use the complete params, so, all Test Cases created with
# => this hooks example will be this following values: Type: Functional, Method: Automated and Priority: Critical.
#
# => The order of params of this function are: workspace, project, name, description,owner, type, method, priority,id*
#
# => At the moment, the id param is useless. For the next review, your use will be studied
#

cucumber = CucumberToRally::CucumberToRally.new

#Params to Connect on Rally
LOGIN = #Insert here your Rally login
PASSWORD = #Insert here your password

#Params to create a Test Case Result
WORKSPACE = #Workspace of the Project
PROJECT = #Id of the Project
BUILD =  #Default build, case you want to define a default Build Name




# The Before do "function" run before each scenario. In this hooks.rb file example, Before the scenario runs, I connect on Rally.

Before do
	# Connect to Rally before the Scenario run. Can be used after the scenario run too.
	cucumber.connect(LOGIN,PASSWORD)
end

#The After do |scenario| "function" runs after each scenario. The scenario variable allow us to make some validations before save the Test Case Result or create a Test Case, if the scenario hasn\'t been created yet.

After do |scenario|

#
# => The following lines are ways to identfy existing Test Cases, but nothing prevents you of using other ways
# => to identify existings Test Cases.
#

	if scenario.source_tag_names.first == nil
		TC_ID = 0
		isId = "none"
	else
		isId = scenario.source_tag_names.first;
		isId = isId.gsub("@","")
	end

	if isId.start_with?("TC")
		TC_ID = isId
	end

	#This "if" will be executed only if the scenario fail.
	if (scenario.failed?)
		begin
			Kernel.puts "The scenario #{scenario.name} failed!" #Sends a message to the prompt!
			if (TC_ID == 0) # Case the TC_ID constant isn\'t defined, a new Test Case will be created!
				begin
					Kernel.puts "Creating Test Case\n" #Sends a message to the prompt!
					newTC = cucumber.createTestCase(WORKSPACE,PROJECT,scenario.name,"Cucumber Execution Test")
					Kernel.puts "Test Case created: " + newTC.to_s # Sends to the prompt, if the Test Case was created.
					cucumber.createFirstTestCaseResult(WORKSPACE,PROJECT,newTC.to_s,BUILD,"Fail") #Create a result for the Test Case created
				end
			else
				cucumber.createTestCaseResult(WORKSPACE,PROJECT,TC_ID,BUILD,"Fail") #Just runs if the ID was informated.
			end
		end
	end

	#This if will be executed only if the scenario pass.
	if (scenario.passed?)
		begin
			Kernel.puts "The scenario #{scenario.name} passed!" #Sends a message to the prompt
			if (TC_ID == 0) # Case the TC_ID constant isn\'t defined, a new Test Case will be created!
				begin
					Kernel.puts "Creating Test Case\n" #Sends a message to the prompt
					newTC = cucumber.createTestCase(WORKSPACE,PROJECT,scenario.name,"Cucumber Execution Test")
					Kernel.puts "Test Case created: " + newTC.to_s # Sends to the prompt, if the Test Case was created.
					cucumber.createFirstTestCaseResult(WORKSPACE,PROJECT,newTC.to_s,BUILD,"Pass") #Create a result for the Test Case created
				end
			else
				cucumber.createTestCaseResult(WORKSPACE,PROJECT,TC_ID,BUILD,"Pass") #Just runs if the ID was informated
			end
		end
	end
end'


module CucumberToRally
class CucumberToRally

	def hook
		if !File.exist?("features/support/hooks.rb")
			newHook = File.new("features/support/hooks.rb","w")
			newHook.write(CONTENT)
		end
	end

	def connect(login,pass)
		begin
			$LOGIN = login
			print "Conecting with Rally...\n"
			rally_logger = Logger.new STDOUT
			rally_logger.level = Logger::INFO
			@rally = RallyRestAPI.new(:username => login, :password => pass, :api_version => "1.29", :logger => rally_logger)
		rescue
			print "Error on connect. Try again...\n"
		else
			print "Logged with success!\n"
		end
	end


	def findTestCaseFull(workspace,project,formattedId)
		begin
			print "Searching Test Case...\n"

			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			fullResult = @rally.find(:test_case, :fetch => true, :workspace => ref=work, :project => ref=proj){ equal :formattedId, formattedId}
		rescue
			print "Error on search. Try again...\n"
		else
			if fullResult.results.length > 0
				begin
					print "Test Case found:#{fullResult.results.first}\n"
					return fullResult.results.first
				end
			else
				begin
					print "Test Case not found\n"
					return nil
				end
			end
		end
	end


	def findTestCaseCompact(workspace,project,formattedId,name="none")
		begin
			print "Searching Test Case.\n"

			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			if (name == "none")
			compactResult = @rally.find(:test_case, :workspace => ref=work, :project => ref=proj){ equal :formattedId, formattedId}
			else
			compactResult = @rally.find(:test_case,:workspace => ref=work, :project => ref=proj){ equal :name, name}
			end
		rescue
			print "Error on search. Try again...\n"
		else
			if compactResult.results.length > 0
				begin
					print "Test Case found:#{compactResult.results.first}\n"
					if (name == "none")
						return compactResult.results.first
					else
						return compactResult.results.last
					end
				end
			else
				begin
					print "Test Case not found...\n"
					return nil
				end
			end
		end
	end

	def findTestCaseById(workspace,project,formattedId)
		begin
			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			returnId = @rally.find(:test_case,:workspace => ref=work, :project =>ref=proj){ equal :formattedID, formattedId}

			if (returnId.results.first != nil)
				return true
			else
				return false
			end

		end
	end

	def createTestCase(workspace, project, name, description,owner=$LOGIN, type="Functional", method="Automated", priority="Critical",id=nil)
		if (id != nil)
			exist = findTestCaseById(workspace,project,id)
		end

		if (exist)
			print ("Test Case exist. Skipping creation\n")

		else
			begin

				tc = findTestCaseCompact(workspace,project,name)

				print "Creating Test Case..\n"

				work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
				proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

				teste = @rally.create(:test_case, :workspace => ref=work, :project => ref=proj, :name => name, :description => description, :owner => owner, :type => type, :method => method, :priority => priority)

			end
		end

	end

	def findTestCaseResult(workspace,project,formattedId)
		begin
			print "Searching Test Case results\n"

			testCase = findTestCaseCompact(workspace,project,formattedId)

			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			testCaseResult = @rally.find(:test_case_result, :workspace => ref=work, :project => ref=proj, :fetch => true){ equal :test_case, testCase  }
		rescue
			print "Error on search. Try again...\n"
		else
			if testCaseResult.results.length > 0
				begin
					print "Founded #{testCaseResult.results.length} Test Cases Results\n"
				end
			else
				begin
					print "No Test Case founded\n"
				end
			end
		end
	end

	def createTestCaseResult(workspace,project,formattedId,build,verdict)
		begin
			print "Creating Test Case Result\n"

			date = Time.now

			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			tc = findTestCaseCompact(workspace,project,formattedId)

			@rally.create(:test_case_result, :workspace => ref=work, :test_case => tc, :build => build, :date => date.iso8601, :verdict => verdict)

		rescue
			print "Error on create Test Case Result. Try again\n"

		else
			print "Test Case Result created with success.\n"
		end
	end

	def createFirstTestCaseResult(workspace,project,name,build,verdict)
		begin
			print "Creating first Test Case result\n"

			date = Time.now

			work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
			proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

			tc = findTestCaseCompact(workspace,project,"none",name)

			@rally.create(:test_case_result, :workspace => ref=work, :test_case => tc, :build => build, :date => date.iso8601, :verdict => verdict)

		rescue
			print "Error on create Test Case result. Try again...\n"

		else
			print "Test Case Result created with success.\n"
		end
	end
end
end
