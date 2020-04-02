
/***
* Name: Simulating the spread of COVID19 virus in my hometown
* Author: Hussain Alsalman
* Description: 
* Tags: Simulations, Infection, IBM, COIVD19
***/

model infections

global {
	
	// Defining the geographical envirnoment 
	
    file buildings_shapefile <- file("../includes/all_buildings.shp");
    file roads_shapefile <- file("../includes/roadsplus.shp");
    geometry shape <- envelope(roads_shapefile);
    graph road_network;
	
	// Defining the times compoenent of the simulation 
	date starting_date <- date([2020,4,2,16,44,44]); 
	float step <- 60 #mn;
	int current_min update: (time / #minutes) mod 1440;	

	
    int nb_people <- 1000;
    int nb_infected_init <- 10;
    
    //Infection Range in meters
    float infect_range <- 4#m;
    
    //Public info
    list<building> residential_buildings;
    list<building> mousqs;
    list<building> resturants;
    list<building> shops;
    list<building> hospitals;
    list<building> supermarket; 
    list<building> other_places; 
    list<building> banks; 
	
	//Gamma parameter used for the resistance gained by the infectious individuals
	float gamma <- 1/ 14#d;
	//Rate for the infection success  : this is porpotional to the number of infected people around the agent at 4#m distance 
	float beta <- 0.05 ;
	
    int nb_people_infected <- 0 update: people count (each.is_infected);
    int nb_people_not_infected <- nb_people - nb_infected_init update: nb_people - nb_people_infected;
    float infected_rate <- nb_people_infected/nb_people;
	float infection_prob <- 0.5;
	int max_stay_duration <- 120; //maximum staying duration is 2 hours
	int min_stay_duration <- 15; // minimum stay duration is 15 minutes
	int pary_time_duration <- 30; // 30 minutes for pray 


	//policies 
	bool active_testing <- false;
	int g_start_day <- 360; // global variable for start of day in minutes 
	int g_end_day <- 1260; // global variable for end of day in minutes
	int slacking <- 240; // slacking time in minutes.
	list<int> prayer_times <- [240,720,900,1080,1200]; // prayer times in minutes
	float testing_effort <- 0.1; 


    init {
	
    // creating buildings
    create building from: buildings_shapefile
    with: [building_type::string(read("amenity"))] {
    switch (building_type) {
        match "atm" { color <- rgb (128,128,128);} //Gray
        match "bank" { color <- rgb (192,192,192);} // silver
        match "cafe" { color <- rgb (128,0,0);} // Maroon
        match "dentist" { color <- rgb (238,232,170);} //pale golden rod
        match "fast_food" { color <- rgb (255,69,0);} //orange red
        match "Gym" { color <- rgb (128,128,0);} // olive
        match "hospital" { color <- rgb (25,25,112);} // midnight blue
        match "library" { color <- rgb (138,43,226);} // blue violet
        match "place_of_worship" { color <- rgb (0,255,0);} // lime
        match "restaurant" { color <- rgb (255,69,0);} // orange red
        match "Shop" { color <- rgb (255,0,255);} // magenta - fuchsia
        match "supermarket" { color <- rgb(255,0,255) ;} // magenta - fuchsia
        match "residential" {color <- rgb(210,180,140,0.8);} // light yellow
        default { color <- rgb (255,255,0);}
    }
}


    // creating roads
    
    create roads from: roads_shapefile;
	road_network <- as_edge_graph(roads);

		residential_buildings <- building where (each.building_type="residential");
		mousqs <- building where (each.building_type="place_of_worship");
		resturants <- building where (each.building_type="restaurant");
		shops <- building where (each.building_type="Shop");
		hospitals <- building where (each.building_type="hospital");
		supermarket <- building where (each.building_type="supermarket");
		banks <- building where (each.building_type="bank");
    	other_places <- building where (each.building_type contains_any ["atm","cafe","dentist","fast_food","Gym","library"]);
    
	
    create people number: nb_people {
		
    	my_home <- one_of(residential_buildings);
    	location <- any_location_in(my_home);
		is_susceptible <- true;
		is_infected <- false;
		is_immune <- false;
		color <- #green;
    	my_mousq <- mousqs closest_to(self);
        my_bank <- banks closest_to(self);
        my_restaurant <- one_of (resturants at_distance 5 #km);
        my_shop <- one_of (shops at_distance 5 #km);
        hospital_near_me <- hospitals closest_to(self);
 		my_supermarket <- one_of (supermarket at_distance 5 #km);
		start_day <- g_start_day + rnd(-slacking,slacking);
		end_day <- g_end_day + rnd(-slacking,slacking);
		}


	ask nb_infected_init among people {
		is_susceptible <- false;
		is_infected <- true;
		is_immune <- false;
		color <- #red;
	}

    }
    reflex end_simulation when: infected_rate = 1.0 {
        do pause;
    }


}

species building {
    string building_type;
    rgb color;
    
    aspect base {
        draw shape color: color ;
    }
}


species roads {
    aspect base {
        draw shape color: #black;
    }
}


species people skills:[moving]  {

	//individual stat 
	point target; // person's next destination ie. the person will be moving as long as he has an objective
	string objective; // The objective is one of ["stay","move","relax"]
	
	
	// attributes of ppeople 
	building my_home; // permenant home 
    building hospital_near_me;
    building my_mousq;
    building my_restaurant;
    building my_shop;
    building my_supermarket;
    building my_bank;
	list<building> errands;
	bool agenda_is_expired; 
	int start_day;
	int end_day;
	int my_watch <- start_day; 
	
	// movements attributes 
	float speed <- (2 + rnd(3)) #km/#h;
	bool is_time_to_move;
	
	// health status
	bool is_susceptible;
	bool is_infected;
	bool is_immune;
	
	
	// Infection Risk 	
	int nb_neighbor_infect  <- 0 update: people at_distance(infect_range) count(each.is_infected);
	
	 //appearance 
	 rgb color <- #green;
	
	
	// Actions behaviors 
	action pray {
		my_watch <- current_min + pary_time_duration;
	}
	
	action complete_task {
		my_watch <-	current_min + rnd (max_stay_duration - min_stay_duration);
	}
	
	action update_my_watch {
		if (objective ="praying"){
			do pray;
			target <- nil;
		}else {
			do complete_task;
			target <- nil;
		}
	}
	
	list<building> get_today_agenda {
		int n_tasks <- 2 +rnd(3);
		return sample([my_restaurant,my_shop,my_supermarket, one_of(other_places), one_of(other_places)],n_tasks,false);
	}
	
	
	reflex set_objective {
		if(objective!="hospitalized"){
		if ((current_min <= start_day) or (current_min >= end_day)){
			objective <- "relax";
		}else if (current_min in prayer_times){
			objective <- "praying";
		}else {
			objective <- "active";
			write "objective is active";
		}} 
	}
	
	reflex is_it_time_to_move when: objective="active" {
		if (current_min >= my_watch){
			is_time_to_move <-  true;
		}else {
			is_time_to_move <- false;
		}
	}
	
	reflex go_home when: objective="relax"{
		point my_home_location <- centroid(my_home);
		do goto target: my_home_location on: road_network;
		if (location = my_home_location) {
    		my_watch <- 0;
   	 }
	}
	

	
	reflex get_my_agenda when: agenda_is_expired and objective="active"{
		errands <- get_today_agenda();
		agenda_is_expired <- false;
	}
	
   reflex go_to_next when: (objective = "active") and (target = nil) and (is_time_to_move){
		
		if(length(errands)>0) {
			building target_building <- errands[0];
			remove index: 0 from: errands;
			target <- any_location_in(target_building);
		} else {
			agenda_is_expired <- true;
			objective <- "relax";
			target <- nil;
		}
	}
	
	reflex go_to_hospital when: active_testing and (is_infected and flip(testing_effort)){
		point hospital_bed <- any_location_in(hospital_near_me); 
		do goto target: hospital_bed on: road_network;
		objective <- "hospitalized";
	}
	
	
	reflex go_pray when: objective="praying" {
		point my_mousq_location <- any_location_in(my_mousq);
		do goto target: my_mousq_location on: road_network;
		if (location = my_mousq_location) {
        	target <- nil;
        	do pray;
        }
	}
	

    reflex move when: !(target = nil) and objective = "active" and is_time_to_move {   
        do goto target: target on: road_network;
        if (location = target) {
			do update_my_watch;
        } 
    }
	
	
	
	reflex become_infected when: is_susceptible and !is_time_to_move {
		if (flip(1 - (1 - beta)  ^ nb_neighbor_infect)) {
			is_susceptible <-  false;
		    	is_infected <-  true;
		    	is_immune <-  false;
		    	color <-  #red;   
		}
	}
	
	//Reflex to pass the agent to the state immune
	reflex become_immune when: (is_infected and flip(gamma)) {
		is_susceptible <- false;
		is_infected <- false;
		is_immune <- true;
		color <- #blue;
		objective <- "relax";
	} 	
    

    aspect circle {
    draw circle(5) color:color;
    }
}
	
experiment main type: gui {

	parameter 'Number of Population' type: int var:  nb_people <- 1000 category: "Initial population";
	parameter 'Number of Infected' type: int var: nb_infected_init <- 5 category: "Initial population";
	parameter 'Beta (S->I)' type: float var: beta <- 0.1 category: "Parameters";
	parameter 'Gamma (I->R)' type: float var: gamma <- step/14#d category: "Parameters";
	parameter 'Infection Distance' type: float var: infect_range <- 5.0#m min: 1.0#m max: 10.0#m category: "Infection";
    output {
        monitor "Infected people rate" value: infected_rate;

        display map {
            species building aspect: base;
            species roads aspect: base;
            species people aspect: circle;

        }

        display chart_display refresh: every(1 #day){
            chart "Disease Spreading" type: series {
				data "susceptible" value: people count (each.is_susceptible) color: #green;
				data "infected" value: people count (each.is_infected) color: #red;
				data "immune" value: people count (each.is_immune) color: #blue;
            }

        }
    }
    
}

experiment with_curvew type: gui {

	parameter 'Number of Population' type: int var:  nb_people <- 1000 category: "Initial population";
	parameter 'Number of Infected' type: int var: nb_infected_init <- 5 category: "Initial population";
	parameter 'Beta (S->I)' type: float var: beta <- 0.1 category: "Parameters";
	parameter 'Gamma (I->R)' type: float var: gamma <- step/14#d category: "Parameters";
	parameter 'Infection Distance' type: float var: infect_range <- 5.0#m min: 1.0#m max: 10.0#m category: "Infection";
	parameter 'start of the day' type: int var:  g_start_day <- 360 min: 360 category: "Curfew";
	parameter 'end of the day' type: int var: g_end_day <- 1140  max: 1140 category: "Curfew";
	parameter 'slack time' type: int var: slacking <- 120 category: "Curfew";
	parameter 'active testing' type: bool var: active_testing <- true category: "MOH efforts";
	parameter 'active testing' type: float var: testing_effort <- 0.1 category: "MOH efforts";
    output {
        monitor "Infected people rate" value: infected_rate;

        display map {
            species building aspect: base;
            species roads aspect: base;
            species people aspect: circle;

        }

        display chart_display refresh: every(1 #day){
            chart "Disease Spreading" type: series {
				data "susceptible" value: people count (each.is_susceptible) color: #green;
				data "infected" value: people count (each.is_infected) color: #red;
				data "immune" value: people count (each.is_immune) color: #blue;
            }

        }
        }
}
    