O que é?

O cucumber-to-rally é uma gem para conectar e atualizar resultados de casos de teste do Rally, assim que um cenário do Cucumber termina de ser executado.
Github

O github da gem é: https://github.com/pspongebob/cucumber-to-rally.
Instalando a gem

No prompt de comando, digite:

“gem install cucumber-to-rally”
Utilizando a gem no seu caso de teste em Cucumber

No env.rb, da pasta Support, você deve adicionar as seguintes linhas:

require ‘cucumber-to-rally’

cucumber = CucumberToRally::CucumberToRally.new

Hooks

Os hooks são ações que são executadas antes ou depois da execução de um cenário Cucumber.

O uso do arquivo hooks padrão é facultativo e você pode codá-lo da maneira que preferir. No caso do exemplo, a única informação que ele necessita é a de pegar o ID do caso de teste através da primeira tag do cenário.
Exemplo de utilização

Primeiro, criaremos a estruturas de pastas e os seguintes arquivos:

- Diretório principal

-- features

--- support

---- env.rb

--- step_definitions

---- teste.rb

--- teste.feature

Agora, definimos o conteúdo do arquivo teste.feature

# language: pt



Funcionalidade: Testar o programa

                Como um pesquisador

                Para realizar a atividade

                Eu quero testar isso aqui



                @TC55

                Cenário: Um nome que ninguém pôs ainda

                               Dado que a página seja a inicial

                               Então o W3C deve ser válido



                Cenário: Validar Grade Yslow

                               Dado que a página seja a inicial

                                Então o W3C deve ser inválido

Repare que no primeiro cenário, há a tag “@TC55”. Essa tag será usada para que quando a gem leia o cenário, ela identifique o cenário e atualize o resultado no Rally. O segundo, como não tem tag, irá criar um novo caso de teste e o resultado desse caso de teste no Rally.

Execute o comando cucumber, para ele criar as funções necessárias para a criação do arquivo teste.rb

# -*- encoding : utf-8 -*-



Dado /^que a página seja a inicial$/ do

  #pending # express the regexp above with the code you wish you had

end



Então /^o W(\d+)C deve ser válido$/ do |arg1|

  #pending # express the regexp above with the code you wish you had

end



Então /^o W(\d+)C deve ser inválido$/ do |arg1|

                raise 'FAIL'

end

Agora a configuração do arquivo env.rb.

require 'cucumber'

require 'cucumber-to-rally'



cucumber = CucumberToRally::CucumberToRally.new

O exemplo abaixo é de um arquivo hooks.rb, onde utiliza-se as tags de cenários para identificar os test cases.

Para esse exemplo, basta preencher os “campos” Login, Password, Workspace, Project e Build.

# -*- encoding : utf-8 -*-





# => The function createTestCase, used in this example, don't use the complete params, so, all Test Cases created with

# => this hooks example will be this following values: Type: Functional, Method: Automated and Priority: Critical.

#

# => The order of params of this function are: workspace, project, name, description,owner, type, method, priority,id.

# => The id in this function is used to verify if the Test Case exists.

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



#The After do |scenario| "function" runs after each scenario. The scenario variable allow us to make some validations before save the Test Case Result or create a Test Case, if the scenario hasn't been created yet.



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

            cucumber.findTestCaseCompact(WORKSPACE,PROJECT,nil,scenario.name)

            Kernel.puts "The scenario #{scenario.name} failed!" #Sends a message to the prompt!

            if (TC_ID == 0) # Case the TC_ID constant isn't defined, a new Test Case will be created!

                begin

                    Kernel.puts "Creating Test Case\n" #Sends a message to the prompt!

                    newTC = cucumber.createTestCase(WORKSPACE,PROJECT,scenario.name,"Cucumber Execution Test")

                    Kernel.puts "Test Case created: " + newTC.to_s # Sends to the prompt, if the Test Case was created.

                    cucumber.createTestCaseResult(WORKSPACE,PROJECT,nil,BUILD,"Fail",scenario.name) #Create a result for the Test Case created

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

            if (TC_ID == 0) # Case the TC_ID constant isn't defined, a new Test Case will be created!

                begin

                    Kernel.puts "Creating Test Case\n" #Sends a message to the prompt

                    newTC = cucumber.createTestCase(WORKSPACE,PROJECT,scenario.name,"Cucumber Execution Test")

                    Kernel.puts "Test Case created: " + newTC.to_s # Sends to the prompt, if the Test Case was created.

                    cucumber.createFirstTestCaseResult(WORKSPACE,PROJECT,nil,BUILD,"Pass",scenario.name) #Create a result for the Test Case created

                end

            else

                cucumber.createTestCaseResult(WORKSPACE,PROJECT,TC_ID,BUILD,"Pass") #Just runs if the ID was informated

            end

        end

    end

end

Os parâmetros do inicio do arquivo hooks.rb serão strings, como os ID’s do projeto e workspace, login, senha e build.

O Project você consegue através da URL do Rally.

Exemplo: em https://rally1.rallydev.com/#/5019709652d/oiterationstatus?iterationKey=-1, a parte em destaque é o ID do Project.

A Build pode ser um texto padrão ou algo que varia de acordo com algum evento do local em que você utiliza.

Tendo preenchido esses dados, basta rodar e ler as mensagens que o prompt exibe.
Métodos

No rubydocs(http://rubydoc.info/gems/cucumber-to-rally/0.1.3/frames) há o exemplo de como se utiliza os métodos da gem.
