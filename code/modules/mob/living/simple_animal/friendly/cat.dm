//Cat
/mob/living/simple_animal/cat
	name = "cat"
	desc = "A domesticated, feline pet. Has a tendency to adopt crewmembers."
	icon_state = "cat2"
	icon_living = "cat2"
	icon_dead = "cat2_dead"
	speak = list("Meow!","Esp!","Purr!","HSSSSS")
	speak_emote = list("purrs", "meows")
	emote_hear = list("meows","mews")
	emote_see = list("shakes their head", "shivers")
	speak_chance = 1
	turns_per_move = 5
	meat_type = /obj/item/reagent_container/food/snacks/meat
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	var/turns_since_scan = 0
	var/mob/living/simple_animal/mouse/movement_target
	min_oxy = 16 //Require atleast 16kPA oxygen
	minbodytemp = 223		//Below -50 Degrees Celcius
	maxbodytemp = 323	//Above 50 Degrees Celcius
	holder_type = /obj/item/holder/cat
	mob_size = MOB_SIZE_SMALL
	sight = SEE_MOBS
	see_in_dark = 8
	see_invisible = 15

/mob/living/simple_animal/cat/initialize_pass_flags(var/datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_pass = PASS_FLAGS_CRAWLER

/mob/living/simple_animal/cat/Life(delta_time)
	//MICE!
	if((src.loc) && isturf(src.loc))
		if(!stat && !resting && !buckled)
			for(var/mob/living/simple_animal/mouse/M in view(1,src))
				if(!M.stat)
					M.splat()
					INVOKE_ASYNC(src, .proc/emote, pick("bites \the [M]!","toys with \the [M].","chomps on \the [M]!"))
					movement_target = null
					stop_automated_movement = 0
					break

	..()

	for(var/mob/living/simple_animal/mouse/snack in oview(src, 3))
		if(prob(15))
			INVOKE_ASYNC(src, .proc/emote, pick("hisses and spits!","mrowls fiercely!","eyes [snack] hungrily."))
		break

	if(!stat && !resting && !buckled)
		handle_movement_target()

/mob/living/simple_animal/cat/death()
	. = ..()
	if(!.)	return //was already dead
	if(last_damage_data)
		var/mob/user = last_damage_data.resolve_mob()
		if(user)
			user.count_niche_stat(STATISTICS_NICHE_CAT)

/mob/living/simple_animal/cat/proc/handle_movement_target()
	turns_since_scan++
	if(turns_since_scan > 5)
		walk_to(src,0)
		turns_since_scan = 0

		if((movement_target) && !(isturf(movement_target.loc) || ishuman(movement_target.loc) ))
			movement_target = null
			stop_automated_movement = 0
		if( !movement_target || !(movement_target.loc in oview(src, 4)) )
			movement_target = null
			stop_automated_movement = 0
			for(var/mob/living/simple_animal/mouse/snack in oview(src))
				if(isturf(snack.loc) && !snack.stat)
					movement_target = snack
					break
		if(movement_target)
			stop_automated_movement = 1
			walk_to(src,movement_target,0,3)

/mob/living/simple_animal/cat/MouseDrop(atom/over_object)

	var/mob/living/carbon/H = over_object
	if(!istype(H) || !Adjacent(H)) return ..()

	if(H.a_intent == INTENT_HELP)
		get_scooped(H)
		return
	else
		return ..()

/mob/living/simple_animal/cat/get_scooped(var/mob/living/carbon/grabber)
	if (stat >= DEAD)
		return
	..()

//RUNTIME IS ALIVE! SQUEEEEEEEE~
/mob/living/simple_animal/cat/Runtime
	name = "Runtime"
	desc = "Her fur has the look and feel of velvet, and her tail quivers occasionally."
	icon_state = "cat"
	icon_living = "cat"
	icon_dead = "cat_dead"

/mob/living/simple_animal/cat/Jones
	name = "Jones"
	desc = "A tough, old stray whose origin no one seems to know."
	icon_state = "cat2"
	icon_living = "cat2"
	icon_dead = "cat2_dead"
	health = 50
	maxHealth = 50
	holder_type = /obj/item/holder/Jones

/mob/living/simple_animal/cat/kitten
	name = "kitten"
	desc = "D'aaawwww"
	icon_state = "kitten"
	icon_living = "kitten"
	icon_dead = "kitten_dead"
	gender = NEUTER
