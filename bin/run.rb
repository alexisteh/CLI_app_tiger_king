require_relative '../config/environment.rb'
require 'pry'
require 'terminal-table'

#blank tigers before buying: bought = false, alive = true, time_born = nil
#blank tigers after buying: bought = true, alive = true, time_born = nil  
#living tigers in zoo: bought = true, alive = true, time_born != nil
#dead tigers in zoo: bought = true, alive = false, time_born != nil
#sold tigers: bought = false, alive = nil, time_born != nil

$prompt = TTY::Prompt.new 
 

def entry_screen 
    choices = ["Play the game", "Look at Highscore"]
    choice = $prompt.select("Welcome! Here are your options:", choices)
    if choice == "Play the game"
        opening_message         
    end 
end 


def opening_message 
    input = $prompt.yes?("Do you want to own tigers?")
    if input == true 
        pick_character_and_zoo 
    else 
        puts "You were eaten by a tiger!"
        return 
    end 
end 

def pick_character_and_zoo
    choices = ["Joe Exotic", "Carole Baskin", "Doc Bhagaven Antle", "Jeff Lowe"]
    char_name = $prompt.select("Pick your character!", choices)
    if char_name == "Joe Exotic" 
        start_money = 1200 
    elsif char_name == "Carole Baskin"
        start_money = 800 
    elsif char_name == "Doc Bhagaven Antle"
        start_money = 1500
    else start_money = 1000 
    end 
    zookeeper_object = Zookeeper.create(name: char_name, alive: true)  
    puts "Welcome," + char_name +" !" 

    zoo_name = $prompt.ask("Now, name your zoo:")
    Zoo.create(name: zoo_name, money: start_money, zookeeper_id: zookeeper_object.id)
    puts "You, #{Zookeeper.last.name}, are in charge of #{zoo_name} with starting funds of $#{start_money}!"
    game_run_method
end 

def game_run_method
    
    check_tigers_over_time  

    if Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == true} == [] 
        choices =  [
            'Buy a Tiger',
            {name: 'Sell a Tiger', disabled: 'You do not have a tiger to sell!'},
            {name: 'Feed a Tiger', disabled: 'You do not have a tiger to feed!'},
            {name: 'Showcase a Tiger', disabled: 'You do not have a tiger to showcase!'},
            'Buy Food',
            'Check my Stats' 
            ]
    else 
        choices = [
        'Buy a Tiger',
        'Sell a Tiger', 
        'Feed a Tiger',
        'Showcase a Tiger', 
        'Buy Food',
        'Check my Stats'
        ] 
    end 

    choice = $prompt.select("What would you like to do?", choices) 
    if choice == "Buy a Tiger" 
        buy_tiger 
    elsif choice == "Sell a Tiger"
        sell_tiger
    elsif choice == "Feed a Tiger"
        feed_tiger 
    elsif choice == "Showcase a Tiger"
        showcase_tiger
    elsif choice == "Buy Food"
        buy_food
    elsif choice == "Check my Stats"
        check_stats    
    end  
end 

def check_stats 
    
    current_money = Zoo.last.money 
    current_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == true}.map(&:name).join(", ") 
    dead_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == false}.map(&:name).join(", ")
    current_food_supply = Zoo.last.foods.map(&:name).join(", ") 

    choices = ["Check on Tigers", "Check my Zoo Stats"]
    input = $prompt.select("Choose what you want to check!", choices)

    if input == "Check on Tigers"
        check_health 
    elsif input == "Check my Zoo Stats"
        rows = []
        rows << ['Current Funds', current_money]
        rows << ['Your Tigers', current_tigers]
        rows << ['Dead Tigers', dead_tigers]
        rows << ['Your Food Supply', current_food_supply]
        zoo_stats_table = Terminal::Table.new :title => "Your Zoo Stats", :rows => rows
        zoo_stats_table.style = {:width => 40, :padding_left => 3, :border_x => "=", :border_i => "x"}
        puts zoo_stats_table 
        game_run_method
    end
end 

def check_tigers_over_time
    existing_tigers = Tiger.all.select{|t| t.bought == true && t.zoo_id == Zoo.last.id && t.alive == true}
    if existing_tigers.length == 0 
        return 
    end 
    existing_tigers.each do |tiger_object|
        if tiger_object.time_last_fed == nil 
            time_considered = tiger_object.time_born 
        else time_considered = tiger_object.time_last_fed 
        end 
        if Time.now - time_considered > 240.0 
            resulting_health = tiger_object.health - 20 
            tiger_object.update_attribute(:health, resulting_health)
        elsif Time.now - tiger_object.time_last_fed > 80.0 
        end 
         
        if 
            
        end 
        
        if tiger_object.health <= 0 
            puts "#{tiger_object.name} is dead."
            tiger_object.update_attribute(:alive, false)
        else 
            puts "#{tiger_object.name} is alive and well."
        end 
    # set tiger status to dead if health <= 0 
    # set tiger status to dead if not fed recently enough 
end 

def check_health 

    existing_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id} 
    
    if existing_tigers.length == 0  
        puts "You do not have any existing Tigers!"
        game_run_method 
    else 
        rows = [] 
        rows << ["Name", "Alive?", "Health", "Feeding Status"]  

        existing_tigers.each do |tiger_object| 

            if tiger_object.time_last_fed == nil 
                time_considered = tiger_object.time_born 
            else time_considered = tiger_object.time_last_fed 
            end 

            if Time.now - time_considered > 240.0 
                resulting_health = tiger_object.health - 20 
                tiger_object.update_attribute(:health, resulting_health)
                feeding_status = "Needs to be fed!" 
            elsif Time.now - tiger_object.time_last_fed > 80.0 
                feeding_status = "Needs to be fed soon!"
            else message = "Well-nourished!"
            end 

            if tiger_object.health <= 0 
                tiger_object.update_attribute(alive: false)
                living_status = "dead"
                feeding_status = "–" 
            else living_status = "alive"
            end 
            rows << [tiger_object.name, living_status, tiger_object.health, feeding_status]  
        end 
        tiger_stats_table = Terminal::Table.new :title => "Your Tiger Stats", :rows => row 
        game_run_method
    end 
end 
 

def buy_tiger 
    #pick from unbought tigers to buy from. in each session, rake::seed clears all non-blank_zoo tigers. 
    choices = Tiger.all.select{|tiger| (tiger.bought == false) && (tiger.alive == true)}.map(&:name) 
    tiger_chosen = $prompt.select("Pick your tiger!", choices) 
    tiger_object = Tiger.find_by(name: tiger_chosen) 
    
    if Zoo.last.money >= tiger_object.price  
        tiger_object.update_attribute(:bought, true)  #same tiger cannot be bought again 
        new_tiger = tiger_object.dup  #tiger instance duplicated to current zo
        new_tiger.save 
        new_tiger.update_attribute(:time_born, Time.now) #set time born to new tiger 
        new_tiger.update_attribute(:zoo_id, Zoo.last.id) #set current zoo_id to new tiger 
        resulting_money = Zoo.last.money - tiger_object.price  #updates zoo's money 
        Zoo.last.update_attribute(:money, resulting_money)
        puts "Congrats, #{Zookeeper.last.name}! You just bought #{tiger_chosen}!"
        game_run_method 
    else 
        puts "You do not have enough money to buy this tiger!"
        game_run_method
    end 
end 


def buy_food 
    choices = Food.all.map{|food| food.name + " for $#{food.price}"}
    food_choice = $prompt.select("Which food will you feed your tiger today?", choices).split(" ")
    food_choice.pop(2)
    food_choice = food_choice.join(" ") 
    price = Food.all.find_by(name: food_choice).price  

    if Zoo.last.money >= price 
        puts "You just bought #{food_choice}!" 
        Zoofood.create(zoo_id: Zoo.last.id, food_id: Food.all.find_by(name: food_choice).id) #add food to zoo through joiner class
        resulting_money = Zoo.last.money - price #update money after buying food 
        Zoo.last.update_attribute(:money, resulting_money)
        game_run_method 
    else 
        puts "You do not have enough money to buy this food product!"
        game_run_method
    end 
end 


def sell_tiger 
    available_tigers = Tiger.all.select{|tiger| (tiger.bought == true) && (tiger.zoo_id == Zoo.last.id) && (tiger.alive == true)}
    if available_tigers.length == 0 
        puts "you have no tigers!"
        game_run_method
    else 
        choices = available_tigers.map{|tiger| tiger.name + " (bought for #{tiger.price})"} 
        tiger_chosen = $prompt.select("Pick a tiger to sell!", choices).split(" ")
        tiger_chosen.pop(3)
        tiger_object = Tiger.all.find_by(name: tiger_chosen.join(" "), bought: true, zoo_id: Zoo.last.id, alive: true)
        price = tiger_object.price 
        health = tiger_object.health 

        if health >= 50
            sell_price = (price*((1+(health/200))*(1+0.5*(rand)))).to_i 
            resulting_money = Zoo.last.money + sell_price  
            Zoo.last.update_attribute(:money, resulting_money)
            Zoo.last.save 
            tiger_object.update_attribute(:bought, false) 
            tiger_object.update_attribute(:alive, nil) 
            puts "You just sold #{tiger_chosen.join(" ")} for #{sell_price}! Say goodbye to your tiger!"
            game_run_method 
        elsif health <= 50
            puts "This Tiger is too sick too sell!"
            game_run_method
        end 
    end 
end 

def showcase_tiger 
    available_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == true}
    
    if available_tigers.length == 0
        puts "You have no tigers!"
        game_run_method
    else 
        tiger_choices = available_tigers.map(&:name)  
        tiger_chosen = $prompt.select("Pick a tiger to showcase at your local mall!", tiger_choices) 
        tiger_object = Tiger.all.find_by(name: tiger_chosen, zoo_id: Zoo.last.id, bought: true, alive: true)
        health = tiger_object.health.to_f 
        price = tiger_object.price.to_f 

        input = $prompt.yes?("Are you sure you want to submit this tiger to torture?")
        if input == true
            money_made = (price*2*(0.5+(health/400.0))).to_i  
            resulting_money = Zoo.last.money + money_made 
            Zoo.last.update_attribute(:money, resulting_money) 
            updated_health = health - 50  
            tiger_object.update_attribute(:health, updated_health)  
            if updated_health <= 0 
                puts "You made #{money_made}, but #{tiger_chosen} is hurt so badly it died!" 
            else puts "You made #{money_made}, but #{tiger_chosen} is traumatized! #{tiger_chosen}'s health went down to #{updated_health}."
            end 
            game_run_method 
        else 
            puts "You are very kind!"
            game_run_method
        end
    end
end 

def feed_tiger 
    available_tigers = Tiger.all.select{|tiger| tiger.bought == true && tiger.zoo_id == Zoo.last.id && tiger.alive == true}
    available_foods = Zoo.last.foods 
    if available_tigers.length == 0 || available_foods.length == 0 
        if available_tigers.length == 0 && available_foods.length == 0 
            puts "You have no tigers and no food!" 
        elsif available_foods.length == 0 
            puts "You don't have any food supplies!"
        else
            puts "You don't have any tigers to feed!"
        end 
        game_run_method
    else 
        tiger_choices = available_tigers.map(&:name)
        tiger_chosen = $prompt.select("Choose a Tiger to feed!", tiger_choices)
        food_choices = available_foods.map(&:name).uniq 
        food_chosen = $prompt.select("What do you want to feed your tiger?", food_choices)  

        tiger_object = Tiger.all.find_by(name: tiger_chosen, zoo_id: Zoo.last.id, bought: true, alive: true) 
        tiger_object.update_attribute(:time_last_fed, Time.now) 
        food_object = Food.all.find_by(name: food_chosen) 
        tiger_object.update_attribute()
        zoofood_object = Zoofood.all.find_by(zoo_id: Zoo.last.id, food_id: food_object.id)
        zoofood_object.update_attribute(:zoo_id, nil) 
        puts "Chomp chomp chomp!"
        
        # Determine whether the tiger prefers the given food or not 
        
        tied_blank_tiger = Tiger.all.find_by(name: tiger_chosen, bought: true, alive: true, time_born: nil)  
        binding.pry 
        if FoodPreference.find_by(food_id: food_object.id, tiger_id: tied_blank_tiger.id)  
            change = 40  
            puts "Your tiger #{tiger_chosen} is very happy!" 
        elsif food_chosen == "Walmart Meats"
            change = -40 
            puts "Your Tiger is ill! Don't feed him Walmart Meat next time!"
        else 
            change = 5
            puts "Your #{tiger_chosen} doesn't really enjoy that food!" 
        end
 
        updated_health = tiger_object.health + change  
        tiger_object.update_attribute(:health, updated_health)
        puts "Your tiger's new health is now #{updated_health}."
        game_run_method 
     
    end 
end 

# f2 = Zoofood.create(zoo_id: Zoo.last.id, food_id: Food.find_by(name: "Organic Chicken").id) 
# f3 = Zoofood.create(zoo_id: Zoo.last.id, food_id: Food.find_by(name: "Beef").id) 
# f3 = Zoofood.create(zoo_id: Zoo.last.id, food_id: Food.find_by(name: "Beef").id) 
# f3 = Zoofood.create(zoo_id: Zoo.last.id, food_id: Food.find_by(name: "Walmart Meats").id) 




# turn_choices = ["feed tiger", "sell tiger", "showcase a tiger", "buy food"]
# turn_choice = $prompt.select("Options:", turn_choices)

showcase_tiger 