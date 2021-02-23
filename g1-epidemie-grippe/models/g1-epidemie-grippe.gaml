
/**
* Name: contaminationgrippe
* Based on the internal skeleton template. 
* Author: fafou
* Tags: 
*/

model epidemie_grippe


global {
	file shape_file_batiments <- file("../includes/buildings.shp");
	file shape_file_routes <- file("../includes/road.shp");
	file shape_file_bounds <- file("../includes/bornes.shp");
	geometry shape <- envelope(shape_file_bounds);
	
	float step <- 5 #mn;
	int distance_infection <- 2;
	int nbr_personne <-400;
	int nb_delegue <- rnd(100, 300);
	int current_hour update: (time / #hour) mod 24;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 2.0 #km / #h; 
	float destroy <- 0.02;
	int repair_time <- 2 ;
	graph the_graph;
	float rayon_contamination <- 5.0;
	
    int nbr_infecte; 
    int nbr_traite;
    
	
	init {
		
		create batiment from: shape_file_batiments with: [type::string(read ("NATURE"))] {
			if type="Industrial" {
				color <- #yellow ;
				border <- #black;
			} else if type="Hospital" {
				color <- #green;
				border <- #black;
			} else {
				color <- #gray;
				border <- #black;
			}
		}
		create route from: shape_file_routes ;
		
		
		list<batiment> residence_batiments <- batiment where (each.type="Residence");
		list<batiment> lieu_dactivite_batiments <- batiment  where (each.type="lieu_dactivite") ;
		list<batiment> hopital_batiments <- batiment  where (each.type="Hospital") ;
		
		create delegue number: nb_delegue {
			state <- rnd(1, 3);
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			living_place <- one_of(residence_batiments) ;
			working_place <- one_of(lieu_dactivite_batiments) ;
			healing_place <- one_of(hopital_batiments);
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
		
		create medecin number: 10 {
			color <- #blue;
			state <- rnd(1, 3);
			speed <- min_speed + rnd (max_speed - min_speed) ;
			start_work <- min_work_start + rnd (max_work_start - min_work_start) ;
			end_work <- min_work_end + rnd (max_work_end - min_work_end) ;
			living_place <- one_of(residence_batiments) ;
			working_place <- one_of(lieu_dactivite_batiments) ;
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
	}
}

species batiment {
	string type; 
	rgb color <- #gray  ;
	rgb border <- #black;
	int nbr_personne <-0;
	int capacite_reception;
	
	aspect base {
		draw shape color: #orange depth: 80.0;
	}
}

species hopital parent: batiment {
	 	
}

species route{
	float destruction_coeff <- rnd(1.0,2.0) max: 2.0;
    int colorValue <- int(255*(destruction_coeff - 1)) update: int(255*(destruction_coeff - 1));
    rgb color <- rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0)  update: rgb(min([255, colorValue]),max ([0, 255 - colorValue]),0) ;
	aspect geom {
        draw shape color: #black;
    }
}

species Personne skills:[moving]  {
	float speed <- 0.5;
    bool est_infecte <- false;
	int immu_sys;
	int temp_avec_maladie;
	rgb color;
	int state;
	float taille <-5.0;
	batiment living_place <- nil ;
	batiment working_place <- nil ;
	batiment healing_place <- nil;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
		
	reflex time_to_work when: current_hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	reflex time_to_go_home when: current_hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	  
	reflex move{
    do wander;
    }
    
    reflex infect when: est_infecte{
    ask Personne at_distance 2 #m {
        if flip(0.05) {
        nbr_infecte <- 1;
        }
      }
    }
    
    aspect circle {
    draw circle(10) color:color;
    }
}

species delegue parent: Personne {
	int immu_sys <- rnd(100, 300);
	int temp_maladie_grow;
	int temp_avec_maladie <- 0;
	
	list<delegue> all_delegue <- list(delegue);
	
	reflex update_stat {
	    nbr_traite <- all_delegue count (each.state = 1);
	    nbr_infecte <- all_delegue count (each.state = 2);
	}
	
	reflex infect {
		ask delegue at_distance(distance_infection){
			if self.state = 2 {
				myself.color <- #red;
				myself.state <- 2;
		}
		}
	}
	
	reflex contaminer_zone {
	
		if self.state = 2 {
//			do create_zone_contamination();	
		} 
	}
	
	action create_zone_contamination {
		create virus number: 1 {
			age <- 1;
			rayon_contagion <- 1;
			position <- self.location;
		}
	}
	


reflex mourir {
		if self.state = 2 and temp_maladie_grow {
			immu_sys <- immu_sys - 1;
			temp_maladie_grow <- 0;
		}
		if immu_sys <= 0 {
			do die;
		}
		temp_maladie_grow <- temp_maladie_grow + 1;
	}
	
	reflex verifier_etat {
		 if state = 1 {
			color <- #green;
		} else{
			color <- #red;
	 }
	}
	
	aspect base {
		if self.state = 2 {
			draw circle(10) color: color border: #black;
		}  else {
			draw square(20) color: color border: #black;
		}
	}
}

species virus {
	int age;
	int rayon_contagion;
	int max_age <- int(10);
	rgb color <- #white;
	int speed_grow <- 2;
	point position;
	
	reflex mourir {
		if age >= max_age {
			do die;
		}
	}
	
	reflex grandir {
		if speed_grow >= 5 {
			rayon_contagion <- rayon_contagion + 1;
			speed_grow <- 1;
			age <- age + 1;
		}
		speed_grow <- speed_grow + 1;
	}
	
	reflex contaminer {
		list nearest_agents <- agents_at_distance(2) ;
		
		if (length(nearest_agents) > 0) {
			loop i from:0 to: (length(nearest_agents) - 1) {
				delegue ag <- (delegue(nearest_agents at i));
				if (ag != nil){
					if ag.state = 1 or ag.state = 2 {
						ag.color <- #red;
							
					}	
				}	
			}
		}
	}	
	
	aspect base {
		draw square(rayon_contagion) color: color;
	}
}

species medecin parent: Personne{

	aspect base {
		draw circle(15) color: #blue depth: 3.0;
	}	
}

experiment epidemie_grippe type: gui {
	parameter "Shapefile pour les batiments:" var: shape_file_batiments category: "GIS" ;
	parameter "Shapefile pour les routes:" var: shape_file_routes category: "GIS" ;
	parameter "Shapefile pour les contour:" var: shape_file_bounds category: "GIS" ;
	parameter "Nombre d'agent delegue" var: nb_delegue category: "delegue" ;
	parameter "heure le plus tot pour comencer le travail" var: min_work_start category: "delegue" min: 2 max: 8;
	parameter "Heure plus tard pour commencer le travail" var: max_work_start category: "delegue" min: 8 max: 12;
	parameter "Heure plus tot pour quitter le travail" var: min_work_end category: "delegue" min: 12 max: 16;
	parameter "Heure plus tard pour quitter le travail" var: max_work_end category: "delegue" min: 16 max: 23;
	parameter "vitesse minimale" var: min_speed category: "delegue" min: 0.5 #km/#h ;
	parameter "vitesst maximale" var: max_speed category: "delegue" max: 10 #km/#h;
	parameter "Valeur de destruction quand un delegue emprunte la route" var: destroy category: "route" ;
	parameter "Nombre d'heure pour la reparation" var: repair_time category: "route" ;
	
	output {
		display city_display type:opengl {
			species batiment aspect: base ;
			species route aspect: geom ;
			species delegue aspect: base ;
			species virus aspect: base;
			species medecin aspect: base;
			
			}
		display chart_display refresh: every(10#cycles){
			chart "graphe" type:pie {
            	data "infecte" value: nbr_infecte color: #red;
        		data "retabli" value: nbr_traite color: #green;
        		
            }
      }
	}
}
