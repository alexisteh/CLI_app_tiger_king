class Interface

    def self.opening_display 
        puts "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
        
                                                                                                         
        ███      ▄█     ▄██████▄     ▄████████    ▄████████        ▄█   ▄█▄   ▄█  ███▄▄▄▄      ▄██████▄ 
    ▀█████████▄ ███    ███    ███   ███    ███   ███    ███        ███ ▄███▀ ███  ███▀▀▀██▄   ███    ███      
       ▀███▀▀██ ███▌   ███    █▀    ███    █▀    ███    ███        ███▐██▀   ███▌ ███   ███   ███    █▀       
        ███   ▀ ███▌  ▄███         ▄███▄▄▄      ▄███▄▄▄▄██▀       ▄█████▀    ███▌ ███   ███  ▄███             
        ███     ███▌ ▀▀███ ████▄  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀        ▀▀█████▄    ███▌ ███   ███ ▀▀███ ████▄       
        ███     ███    ███    ███   ███    █▄  ▀███████████        ███▐██▄   ███  ███   ███   ███    ███      
        ███     ███    ███    ███   ███    ███   ███    ███        ███ ▀███▄ ███  ███   ███   ███    ███      
       ▄████▀   █▀     ████████▀    ██████████   ███    ███        ███   ▀█▀ █▀    ▀█   █▀    ████████▀       
                                                 ███    ███        ▀                                         
                      MURDER. MAYHEM. MADNESS.                                                                                                                                                                                                                                      
        \n".colorize(:light_red)
        self.opening_message
    end 

    def self.opening_message 
        #razzle dazzle letters 
        input = $prompt.yes?("Do you want to own tigers?".colorize(:cyan))
        if input == true 
            choices = ["Start your Tiger zoo!", "View Highscores"]
            $prompt.select("What would you like to do?".colorize(:cyan), choices) do |c| 
                c.choice "Start your Tiger zoo!", -> {self.pick_character_and_zoo}
                c.choice "View Highscores", -> {self.show_highscores}
            end 
        else 
            puts "You were eaten by a tiger!".colorize(:red)
            exit
        end 
    end 
    
    def self.show_highscores
        top_games = Zoo.order(:money).last(5).reverse 
        rows = [] 
        top_games.each do |zoo| 
            zookeeper_name = Zookeeper.find(zoo.zookeeper_id).name 
            rows << [zoo.name, zookeeper_name, zoo.money] 
        end  
        highscores_table = Terminal::Table.new :title => "High Scores", :rows => rows
        highscores_table.style = {:width => 100, :padding_left => 3, :border_x => "=", :border_i => "x"}
        puts highscores_table 
        choices = ["Play the game", "Leave the game"]
        $prompt.select("What would you like to do next?".colorize(:cyan), choices) do |c| 
            c.choice "Play the game", -> {self.pick_character_and_zoo}
            c.choice "Leave the game", -> {self.exit_simple}
        end 
    end 

    def self.pick_character_and_zoo
        choices = ["Joe Exotic", "Carole Baskin", "Doc Bhagaven Antle", "Jeff Lowe"]
        char_name = $prompt.select("Pick your character!".colorize(:cyan), choices)
        if char_name == "Joe Exotic" 
            start_money = 1200 
        elsif char_name == "Carole Baskin"
            start_money = 800 
        elsif char_name == "Doc Bhagaven Antle"
            start_money = 1500
        else start_money = 1000 
        end 
        zookeeper_object = Zookeeper.create(name: char_name, alive: true)  
        puts "Welcome, " + char_name +" !" 
    
        zoo_name = $prompt.ask("Now, name your zoo:".colorize(:cyan))
        Zoo.create(name: zoo_name, money: start_money, zookeeper_id: zookeeper_object.id)
        puts "You, #{Zookeeper.last.name}, are in charge of #{zoo_name} with starting funds of $#{start_money}!"
        self.game_run_method 
    end 

    def self.game_run_method
        self.check_tigers_over_time  #gives tiger status messages and updates healths 
        self.check_stats #prints zoo stats for reference on every round 
        self.fun_message #prints fun random message 
    
        if Tiger.available_tigers.length == 0 
            choices =  [
                'Buy a Tiger',
                {name: 'Sell a Tiger', disabled: '(You do not have a tiger to sell!)'},
                {name: 'Feed a Tiger', disabled: '(You do not have a tiger to feed!)'},
                {name: 'Showcase a Tiger', disabled: '(You do not have a tiger to showcase!)'},
                'Buy Food',
                'Check on Tigers',
                'Exit Game'
                ]
        else 
            choices = [
            'Buy a Tiger',
            'Sell a Tiger', 
            'Feed a Tiger',
            'Showcase a Tiger', 
            'Buy Food',
            'Check on Tigers',
            'Exit Game'
            ] 
        end 
    
        choice = $prompt.select("What would you like to do?".colorize(:cyan) , choices) 
        if choice == "Buy a Tiger" 
            Tiger.buy_tiger
        elsif choice == "Sell a Tiger"
            Tiger.sell_tiger 
        elsif choice == "Feed a Tiger"
            Tiger.feed_tiger 
        elsif choice == "Showcase a Tiger"
            Tiger.showcase_tiger
        elsif choice == "Buy Food"
            Food.buy_food
        elsif choice == "Check on Tigers"
            self.check_health  
        elsif choice == 'Exit Game'
            self.exit_game
        end  
    end 

    def self.time_considered(tiger_object)
        #helper method for check_tigers_over_time to decide time born / fed to compare
        if tiger_object.time_last_fed == nil 
            return tiger_object.time_born 
        else return time_considered = tiger_object.time_last_fed 
        end 
    end 

    def self.check_tigers_over_time        
        if Tiger.available_tigers.length == 0  
            return #no tigers to update statuses for, returns to previous self.game_run_method 
        end 
        starved_tigers = [] 
        hungry_tigers = [] 
        dead_tigers = [] 

        Tiger.available_tigers.each do |tiger_object|
            #check if tiger was fed recently 
            if Time.now - self.time_considered(tiger_object) > 120.0 
                resulting_health = tiger_object.health - 25  
                tiger_object.update_attribute(:health, resulting_health)
                starved_tigers << tiger_object 
            elsif Time.now - self.time_considered(tiger_object) > 60.0 
                hungry_tigers << tiger_object  
            end 
            
            # check if tiger has negative health, or died 
            if tiger_object.health <= 0 
                tiger_object.update_attribute(:health, 0) 
                tiger_object.update_attribute(:alive, false)
                dead_tigers << tiger_object  
                hungry_tigers.delete(tiger_object) 
                starved_tigers.delete(tiger_object) 
            elsif tiger_object.health >= 200 
                tiger_object.update_attribute(:health, 200)
            end 
        end 
        
        #prints tiger status messages 
        if starved_tigers != []  
            puts "Tigers are starving: #{starved_tigers.map(&:name).join(", ")}.".colorize(:red) 
        end 
        if hungry_tigers != []  
            puts "Tigers are hungry: #{hungry_tigers.map(&:name).join(", ")}.".colorize(:red)
        end 
        if dead_tigers != []  
            puts "Tigers have died: #{dead_tigers.map(&:name).join(", ")}.".colorize(:red) 
        end 
    end 

    def self.table_wraparound(array, line_number)
        #helper method for wrapping text in self.check_stats 
        array.each_with_index.map do |element, index| 
            if index % line_number == 0 && index != 0 
                "\n#{element.name}" 
            else element.name 
            end 
        end.join(", ")
    end 

    def self.check_stats 
        #prints zoo stats table for reference in every game turn 
        current_money = Zoo.last.money 
        current_tigers = self.table_wraparound(Tiger.available_tigers, 4) 

        dead_tigers_array = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == false}
        dead_tigers = self.table_wraparound(dead_tigers_array, 4)

        sold_tigers_array = Tiger.all.select{|tiger| tiger.bought == false && tiger.zoo_id == Zoo.last.id && tiger.alive == nil}
        sold_tigers = self.table_wraparound(sold_tigers_array, 4)

        unique_foods = Zoo.last.foods.map(&:name).uniq 
        current_food_supply_array = unique_foods.map do |food_name| 
            food_name + ": " + Zoo.last.foods.map(&:name).count(food_name).to_s 
        end 
        new_food = current_food_supply_array.each_with_index.map do |element, index| 
            if index % 3 == 0 && index != 0 
                "\n#{element}"
            else element 
            end 
        end.join(", ")
        
        rows = [] 
        rows << ['Current Funds', current_money]
        rows << ['Your Tigers', current_tigers] 
        rows << ['Dead Tigers', dead_tigers]
        rows << ['Your Food Supply', new_food] 
        zoo_stats_table = Terminal::Table.new :title => "Your Zoo Stats", :rows => rows
        zoo_stats_table.style = {:width => 100, :padding_left => 3, :border_x => "=", :border_i => "x"}
        puts zoo_stats_table 
    end 


    def self.check_health 
        #gives full health and status updates table for all tigers 

        #includes all bought tigers, dead or not. excludes sold tigers. 
        existing_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id} 
        
        if existing_tigers.length == 0  
            puts "You do not have any tigers!".colorize(:red)
            self.game_run_method 
        else 
            rows = [] 
            existing_tigers.each do |tiger_object|
    
                if tiger_object.alive == false 
                    living_status = "dead".colorize(:red)
                    feeding_status = "–".colorize(:red)
                else 
                    living_status = "alive".colorize(:green)
                    if Time.now - self.time_considered(tiger_object) > 240.0 
                        feeding_status = "Needs to be fed!".colorize(:red)
                    elsif Time.now - self.time_considered(tiger_object) > 80.0 
                        feeding_status = "Needs to be fed soon!".colorize(:yellow)
                    else feeding_status = "Well-nourished!".colorize(:green)
                    end 
                end 

                #gives varying color based on health values 
                if tiger_object.health > 100 
                    health_number = "#{tiger_object.health}".colorize(:green) 
                elsif tiger_object.health >50 
                    health_number = "#{tiger_object.health}".colorize(:yellow)
                else 
                    health_number = "#{tiger_object.health}".colorize(:red)
                end   
                rows << [tiger_object.name, living_status, health_number, feeding_status]  
            end 

            tiger_stats_table = Terminal::Table.new :title => "Your Tiger Stats".colorize(:pink), :rows => rows 
            tiger_stats_table.style = {:width => 100, :padding_left => 3, :border_x => "=", :border_i => "x"}
            puts tiger_stats_table
            self.game_run_method
        end 
    end 

    def self.exit_game 
        puts "Thanks for playing Tiger King!".colorize(:yellow) 
        puts "You made $#{Zoo.last.money} in #{Zoo.last.name}. Good job!".colorize(:light_yellow)  
        choices = ["Play again!", "Goodbye for good!", "See Highscores!"] 
        choice = $prompt.select("Pick an option:".colorize(:cyan), choices)
        if choice == "Play again!" 
            self.pick_character_and_zoo
        elsif choice == "See Highscores!"
            self.show_highscores 
        else exit
        end 
    end 
    
    def self.exit_simple 
        puts "Bye!".colorize(:red) 
        exit 
    end 

    def self.fun_message 
        #prints fun random message every game turn 
        if Tiger.available_tigers == [] 
            messages = ["You need to buy some tigers!".colorize(:pink),
                "You don't have any tigers!".colorize(:pink)     
            ]
        else 
            messages = ["#{Tiger.available_tigers.sample.name} yawns lazily!", 
                "#{Tiger.available_tigers.sample.name} is sleeping soundly!",
                "Your tiger #{Tiger.available_tigers.sample.name} looks especially fluffy today!", 
                "#{Tiger.available_tigers.sample.name} is giving off a funky smell!", 
                "Your tiger #{Tiger.available_tigers.sample.name} is prancing about the enclosure!", 
                "#{Tiger.available_tigers.sample.name} is going for a dip in the pool!", 
                "#{Tiger.available_tigers.sample.name} is melancholy today!", 
                "#{Tiger.available_tigers.sample.name} yearns for the wilderness!", 
                "#{Tiger.available_tigers.sample.name} has been made gaunt and feeble by captivity!",
                "#{Tiger.available_tigers.sample.name} has taken a liking to you!",  
                "It's sweltering today at #{Zoo.last.name}!", 
                "Look out, #{Zookeeper.last.name}! There's a tiger behind you!"
            ] 
        end 
        if Tiger.all.select{|tiger| tiger.name == "Floyd" && tiger.zoo_id == Zoo.last.id } == [ ] 
            messages << "Rumours are circulating of a majestic tiger named Floyd. I heard he's pretty hard to pin down, though."
            messages << "Have you gotten Floyd yet?"
        end 
        if Zoo.last.money <= 500 
            messages = ["#{Zoo.last.name} seems to be in some financial trouble!",
                "You need to make more money, #{Zookeeper.last.name}!"
            ] 
        end 
        puts messages.sample.colorize(:light_red)
    end  
end