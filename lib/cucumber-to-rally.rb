$VERBOSE = nil

require 'rubygems'
require 'active_resource'
require 'logger'
require 'rally_rest_api'
require 'date'
require 'time'

module CucumberToRally
	class CucumberToRally

		def connect(login,password)
			begin
				$LOGIN = login
				print "Conecting with Rally...\n"
				rally_logger = Logger.new STDOUT
				rally_logger.level = Logger::INFO
				@rally = RallyRestAPI.new(:username => login, :password => password, :api_version => "1.29", :logger => rally_logger)
			rescue Exception => err
				puts "Error found: " + err.message
			else
				puts "Connected to Rally!"
			end
		end

		def createTestCase(workspace,project,name,description, usId = nil, owner = $LOGIN,type = "Functional", method = "Automated", priority = "Critical")

			begin

				work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
				proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

				if usId != nil #if principal
					begin
						us = findUS(project,usId)

						if us == false #segundo if
							begin #segundo begin
								puts "No User Story found! Creating Test Case without User Story attached"
								@rally.create(:test_case, :workspace => ref=work, :project => ref=proj, :name => name, :description => description, :owner => owner, :type => type, :method => method, :priority => priority)
							end #fim segundo begin
						else #else segundo if
							begin #terceiro begin
								@rally.create(:test_case, :workspace => ref=work, :project => ref=proj, :name => name, :description => description, :owner => owner, :type => type, :method => method, :priority => priority, :work_product => us)
							end #fim terceiro begin
						end #end segundo if
					end
				else
					begin
						@rally.create(:test_case, :workspace => ref=work, :project => ref=proj, :name => name, :description => description, :owner => owner, :type => type, :method => method, :priority => priority)
					end
				end

			rescue Exception => err

			puts "Error found on creation of test case: " + err.message

			else

			puts "Test Case created with success!"

			end # final do begin do método
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
			rescue Exception => err
				print "Error on search Test Case: " + err.message
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

		def createTestCaseResult(workspace,project,formattedId,build,verdict,name = "none")
			begin
				print "Creating Test Case Result\n"

				date = Time.now

				work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
				proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

				if (name == "none")
					tc = findTestCaseCompact(workspace,project,formattedId)
				else
					tc = findTestCaseCompact(workspace,project,formattedId, name)
				end

				@rally.create(:test_case_result, :workspace => ref=work, :test_case => tc, :build => build, :date => date.iso8601, :verdict => verdict)

			rescue Exception => err
				print "Error on create Test Case Result: "  + err.message

			else
				print "Test Case Result created with success.\n"
			end
		end

		def findTestCaseResult(workspace,project,formattedId)
			begin
				print "Searching Test Case results\n"

				testCase = findTestCaseCompact(workspace,project,formattedId)

				work = "https://rally1.rallydev.com/slm/webservice/1.17/workspace/" + workspace
				proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

				testCaseResult = @rally.find(:test_case_result, :workspace => ref=work, :project => ref=proj, :fetch => true){ equal :test_case, testCase  }
			rescue Exception => err
				print "Error on search: " + err.message
			else
				if testCaseResult.results.length > 0
					begin
						print "Found #{testCaseResult.results.length} Test Case Result(s)\n"
					end
				else
					begin
						print "No Test Case founded\n"
					end
				end
			end
		end


		private

		def findUS(project,id)
			begin

				proj = "https://rally1.rallydev.com/slm/webservice/1.17/project/" + project

				user_story = @rally.find(:hierarchical_requirement, :project => ref=proj){equal :formattedId, id}

				if user_story.results.length > 0
					return user_story.results.first
				else
					return false
				end

			rescue Exception => err
				puts "Error found on search: " + err.message
			else
				puts "User Story found!"
			end
		end

	end
end
