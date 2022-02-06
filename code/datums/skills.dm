// Individual skill
/datum/skill
	var/skill_name = "Skill" // Name of the skill
	var/skill_level = 0 // Level of skill in this... skill

/datum/skill/proc/get_skill_level()
	return skill_level

/datum/skill/proc/set_skill(var/new_level, var/mob/owner)
	skill_level = new_level

/datum/skill/proc/is_skilled(var/req_level, var/is_explicit = FALSE)
	if(is_explicit)
		return (skill_level == req_level)
	return (skill_level >= req_level)

// Lots of defines here. See #define/skills.dm

/datum/skill/cqc
	skill_name = SKILL_CQC
	skill_level = SKILL_CQC_DEFAULT

/datum/skill/melee_weapons
	skill_name = SKILL_MELEE_WEAPONS
	skill_level = SKILL_MELEE_DEFAULT

/datum/skill/firearms
	skill_name = SKILL_FIREARMS
	skill_level = SKILL_FIREARMS_DEFAULT

/datum/skill/spec_weapons
	skill_name = SKILL_SPEC_WEAPONS
	skill_level = SKILL_SPEC_DEFAULT

/datum/skill/endurance
	skill_name = SKILL_ENDURANCE
	skill_level = SKILL_ENDURANCE_WEAK

/datum/skill/engineer
	skill_name = SKILL_ENGINEER
	skill_level = SKILL_ENGINEER_DEFAULT

/datum/skill/construction
	skill_name = SKILL_CONSTRUCTION
	skill_level = SKILL_CONSTRUCTION_DEFAULT

/datum/skill/leadership
	skill_name = SKILL_LEADERSHIP
	skill_level = SKILL_LEAD_NOVICE

/datum/skill/leadership/set_skill(var/new_level, var/mob/living/owner)
	..()
	if(!owner)
		return

	if(!ishuman(owner))
		return

	// Give/remove issue order actions
	if(is_skilled(SKILL_LEAD_TRAINED))
		for(var/action_type in subtypesof(/datum/action/human_action/issue_order))
			if(locate(action_type) in owner.actions)
				continue
			give_action(owner, action_type)
	else
		for(var/datum/action/human_action/issue_order/O in owner.actions)
			O.remove_from(owner)

/datum/skill/medical
	skill_name = SKILL_MEDICAL
	skill_level = SKILL_MEDICAL_DEFAULT

/datum/skill/surgery
	skill_name = SKILL_SURGERY
	skill_level = SKILL_SURGERY_DEFAULT

/datum/skill/surgery/set_skill(var/new_level, var/mob/living/owner)
	..()
	if(!owner)
		return

	if(!ishuman(owner))
		return

	// Give/remove surgery toggle action
	var/datum/action/surgery_toggle/surgery_action = locate() in owner.actions
	if(is_skilled(SKILL_SURGERY_NOVICE))
		if(!surgery_action)
			give_action(owner, /datum/action/surgery_toggle)
		else
			surgery_action.update_surgery_skill()
	else
		if(surgery_action)
			surgery_action.remove_from(owner)

/datum/skill/research
	skill_name = SKILL_RESEARCH
	skill_level = SKILL_RESEARCH_DEFAULT

/datum/skill/antag
	skill_name = SKILL_ANTAG
	skill_level = SKILL_ANTAG_DEFAULT

/datum/skill/pilot
	skill_name = SKILL_PILOT
	skill_level = SKILL_PILOT_DEFAULT

/datum/skill/police
	skill_name = SKILL_POLICE
	skill_level = SKILL_POLICE_DEFAULT

/datum/skill/powerloader
	skill_name = SKILL_POWERLOADER
	skill_level = SKILL_POWERLOADER_DEFAULT

/datum/skill/vehicles
	skill_name = SKILL_VEHICLE
	skill_level = SKILL_VEHICLE_DEFAULT

/datum/skill/jtac
	skill_name = SKILL_JTAC
	skill_level = SKILL_JTAC_NOVICE

/datum/skill/execution
	skill_name = SKILL_EXECUTION
	skill_level = SKILL_EXECUTION_DEFAULT

// Skill with an extra S at the end is a collection of multiple skills. Basically a skillSET
// This is to organize and provide a common interface to the huge heap of skills there are
/datum/skills
	var/name //the name of the skillset
	var/mob/owner = null // the mind that has this skillset

	// List of skill datums.
	// Also, if this is populated when the datum is created, it will set the skill levels automagically
	var/list/skills = list()

/datum/skills/New(var/mob/skillset_owner)
	owner = skillset_owner

	// Setup every single skill
	for(var/skill_type in subtypesof(/datum/skill))
		var/datum/skill/S = new skill_type()

		// Fancy hack to convert a list of desired skill levels in each named skill into a skill level in the actual skill datum
		// Lets the skills list be used multipurposely for both storing skill datums and choosing skill levels for different skillsets
		var/predetermined_skill_level = skills[S.skill_name]
		skills[S.skill_name] = S

		if(!isnull(predetermined_skill_level))
			S.set_skill(predetermined_skill_level, owner)

/datum/skills/Destroy()
	owner = null

	for(var/datum/skill/S in skills)
		qdel(S)
		skills -= S

	return ..()

// Checks if the given skill is contained in this skillset at all
/datum/skills/proc/has_skill(var/skill)
	return isnull(skills[skill])

// Returns the skill DATUM for the given skill
/datum/skills/proc/get_skill(var/skill)
	return skills[skill]

// Returns the skill level for the given skill
/datum/skills/proc/get_skill_level(var/skill)
	var/datum/skill/S = get_skill(skill)
	if(QDELETED(S))
		return -1
	return S.get_skill_level()

// Sets the skill LEVEL for a given skill
/datum/skills/proc/set_skill(var/skill, var/new_level)
	var/datum/skill/S = skills[skill]
	if(!S)
		return
	return S.set_skill(new_level, owner)

/datum/skills/proc/increment_skill(var/skill, var/increment, var/cap)
	var/datum/skill/S = skills[skill]
	if(!S || skillcheck(owner, skill, cap))
		return
	return S.set_skill(min(cap,S.skill_level+increment), owner)

/datum/skills/proc/decrement_skill(var/skill, var/increment)
	var/datum/skill/S = skills[skill]
	if(!S)
		return
	return S.set_skill(max(0,S.skill_level-increment), owner)

// Checks if the skillset is AT LEAST skilled enough to pass a skillcheck for the given skill level
/datum/skills/proc/is_skilled(var/skill, var/req_level, var/is_explicit = FALSE)
	var/datum/skill/S = get_skill(skill)
	if(QDELETED(S))
		return FALSE
	return S.is_skilled(req_level, is_explicit)

// Adjusts the full skillset to a new type of skillset. Pass the datum type path for the desired skillset
/datum/skills/proc/set_skillset(var/skillset_type)
	var/datum/skills/skillset = new skillset_type()
	var/list/skill_levels = initial(skillset.skills)

	name = skillset.name
	for(var/skill in skill_levels)
		set_skill(skill, skill_levels[skill])
	qdel(skillset)

/*
---------------------
CIVILIAN
---------------------
*/

/datum/skills/civilian
	name = "Civilian"
	skills = list(
		SKILL_CQC = SKILL_CQC_DEFAULT,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_NONE,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/manager
	name = "Weyland-Yutani Manager" // Semi-competent leader with basic knowledge in most things.
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/manager_survivor
	name = "Weyland-Yutani Manager" //Manager but balanced for survivor, endurance 5 and can build cades
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/manager/director
	name = "Weyland-Yutani Director"
	skills = list(
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_EXECUTION = SKILL_EXECUTION_TRAINED, //can BE people
	)

/datum/skills/civilian/survivor
	name = "Survivor"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/pmc
	name = "Survivor PMC"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/doctor
	name = "Survivor Doctor"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/clf
	name = "Survivor CLF"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_LARGE
	)

/datum/skills/civilian/survivor/scientist
	name = "Survivor Scientist"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/chef
	name = "Survivor Chef"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/miner
	name = "Survivor Miner"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/trucker
	name = "Survivor Trucker"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_VEHICLE = SKILL_VEHICLE_CREWMAN,
	)

/datum/skills/civilian/survivor/engineer
	name = "Survivor Engineer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/chaplain
	name = "Survivor Chaplain"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/marshal
	name = "Survivor Marshal"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/prisoner
	name = "Survivor Prisoner"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)

/datum/skills/civilian/survivor/gangleader
	name = "Survivor Gang Leader"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_SURVIVOR,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL
	)
/*
---------------------
COMMAND STAFF
---------------------
*/

/datum/skills/admiral
	name = "Admiral"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_MASTER,
		SKILL_EXECUTION = SKILL_EXECUTION_TRAINED, //can BE people
	)

/datum/skills/commander
	name = "Commanding Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_JTAC = SKILL_JTAC_MASTER,
		SKILL_EXECUTION = SKILL_EXECUTION_TRAINED, //can BE people
	)

/datum/skills/XO
	name = "Executive Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI, //to fix CIC apc.
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_JTAC = SKILL_JTAC_MASTER,
	)

/datum/skills/SO
	name = "Staff Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/SEA
	name = "Senior Enlisted Advisor"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_PILOT = SKILL_PILOT_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_LARGE,
		SKILL_JTAC = SKILL_JTAC_EXPERT
	)

/datum/skills/SEA/New(var/mob/skillset_owner)
	..()
	give_action(skillset_owner, /datum/action/looc_toggle)

/datum/skills/SEA/Destroy()
	remove_action(owner, /datum/action/looc_toggle)
	return ..()

/datum/skills/CMO
	name = "CMO"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/CMP
	name = "Chief MP"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI
	)

/datum/skills/CE
	name = "Chief Engineer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_MASTER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_JTAC = SKILL_JTAC_MASTER
	)

/datum/skills/RO
	name = "Requisition Officer"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/*
---------------------
MILITARY NONCOMBATANT
---------------------
*/

/datum/skills/doctor
	name = "Doctor"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
	)

/datum/skills/nurse
	name = "Nurse"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
	)

/datum/skills/researcher
	name = "Researcher"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
	)

/datum/skills/pilot
	name = "Pilot Officer"
	skills = list(
		SKILL_PILOT = SKILL_PILOT_EXPERT,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
	)

/datum/skills/crew_chief
	name = "Dropship Crew Chief"
	skills = list(
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
	)

/datum/skills/MP
	name = "Military Police"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED
	)

/datum/skills/MW
	name = "Military Warden"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI
	)

/datum/skills/OT
	name = "Ordnance Technician"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_MASTER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
	)

/datum/skills/CT
	name = "Cargo Technician"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
	)

/*
---------------------
SYNTHETIC
---------------------
*/

/datum/skills/synthetic
	name = "Synthetic"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_MASTER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_MASTER,
		SKILL_SURGERY = SKILL_SURGERY_EXPERT,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_LARGE,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/colonial_synthetic
	name = SYNTH_COLONY
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_PILOT = SKILL_PILOT_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_VEHICLE = SKILL_VEHICLE_LARGE,
		SKILL_JTAC = SKILL_JTAC_BEGINNER,
	)

/*
------------------------------
United States Colonial Marines
------------------------------
*/

/datum/skills/pfc
	name = "Private"
	//same as default

/datum/skills/pfc/crafty
	name = "Crafty Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED
	)

/datum/skills/combat_medic
	name = "Combat Medic"
	skills = list(
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_NOVICE
	)

/datum/skills/combat_medic/crafty
	name = "Crafty Combat Medic"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED
	)

/datum/skills/combat_engineer
	name = "Combat Engineer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/smartgunner
	name = "Squad Smartgunner"
	skills = list(
		SKILL_SPEC_WEAPONS = SKILL_SPEC_SMARTGUN,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/specialist
	name = "Squad Weapons Specialist"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED, //to use c4 in scout set.
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/rto
	name = "Squad Radio Telephone Operator"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
	)

/datum/skills/SL
	name = "Squad Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
	)

/datum/skills/SL/New(mob/skillset_owner)
	..()
	RegisterSignal(skillset_owner, COMSIG_HUMAN_CARRY, .proc/handle_fireman_carry)

/datum/skills/SL/Destroy()
	UnregisterSignal(owner, COMSIG_HUMAN_CARRY)
	return ..()

/datum/skills/SL/proc/handle_fireman_carry(mob/living/M, list/carrydata)
	return COMPONENT_CARRY_ALLOW

/datum/skills/intel
	name = "Intelligence Officer"
	skills = list(
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_JTAC = SKILL_JTAC_TRAINED
	)

/*
-------------------------
COLONIAL LIBERATION FRONT
-------------------------
*/

/datum/skills/clf
	name = "CLF Soldier"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/clf/combat_engineer
	name = "CLF Engineer"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/clf/combat_medic
	name = "CLF Medic"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/clf/specialist
	name = "CLF Specialist"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_TRAINED
	)

/datum/skills/clf/leader
	name = "CLF Leader"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MELEE = SKILL_MELEE_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_EXPERT
	)

/*
-----------
FREELANCERS
-----------
*/

//NOTE: Freelancer training is similar to the USCM's, but with additional construction skills

/datum/skills/freelancer
	name = "Freelancer Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
	)

/datum/skills/freelancer/combat_medic
	name = "Freelancer Medic"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC
	)

/datum/skills/freelancer/SL
	name = "Freelancer Leader"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_JTAC = SKILL_JTAC_EXPERT
	)

/*
--------------------------
UNITED PROGRESSIVE PEOPLES
--------------------------
*/

//NOTE: UPP make up for their subpar gear with extreme training.

/datum/skills/upp
	name = "UPP Private"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_EXPERT,
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED, //mostly here for fireman carry
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED
	)

/datum/skills/upp/combat_engineer
	name = "UPP Sapper"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_EXPERT,
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED
	)

/datum/skills/upp/combat_medic
	name = "UPP Medic"
	skills = list(
		SKILL_MEDICAL = SKILL_MEDICAL_DOCTOR,
		SKILL_SURGERY = SKILL_SURGERY_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER, //trained in medicine more than combat
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT,
		SKILL_CQC = SKILL_CQC_TRAINED
	)

/datum/skills/upp/specialist
	name = "UPP Specialist"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_UPP,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_CQC = SKILL_CQC_MASTER
	)

/datum/skills/upp/SL
	name = "UPP Squad Leader"
	skills = list(
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_JTAC = SKILL_JTAC_EXPERT
	)

/datum/skills/upp/military_police
	name = "UPP Military Police"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_EXPERT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED
	)

/datum/skills/upp/officer
	name = "UPP Officer"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_POLICE = SKILL_POLICE_FLASH,
		SKILL_ENDURANCE = SKILL_ENDURANCE_EXPERT,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/upp/commander
	name = "UPP Command Officer"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_SMALL,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)
/datum/skills/upp/conscript
	name = "UPP Conscript"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_DEFAULT
	)

/*
----------------------------
Private Military Contractors
----------------------------
*/

//NOTE: Compared to the USCM, PMCs have additional firearms training, construction skills and policing skills

/datum/skills/pmc
	name = "PMC Private"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/pmc/medic
	name = "PMC Medic"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER
	)

/datum/skills/pmc/medic/chem
	name = "PMC Medical Investigator"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED
	)

/datum/skills/pmc/smartgunner
	name = "PMC Smartgunner"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_SMARTGUN,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/pmc/specialist
	name = "PMC Specialist"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/pmc/SL
	name = "PMC Leader"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_JTAC = SKILL_JTAC_TRAINED
	)

/datum/skills/pmc/SL/chem
	name = "PMC Lead Investigator"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_RESEARCH = SKILL_RESEARCH_TRAINED,
		SKILL_JTAC = SKILL_JTAC_TRAINED
	)

/datum/skills/pmc/tank_crew
	name = "Vehicle Crewman"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
		SKILL_VEHICLE = SKILL_VEHICLE_CREWMAN,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
	)

/*
---------------------
SPEC-OPS
---------------------
*/

/datum/skills/commando
	name = "Commando"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/commando/medic
	name = "Commando Medic"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_JTAC = SKILL_JTAC_BEGINNER
	)

/datum/skills/commando/leader
	name = "Commando Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_EXPERT,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
	)

/datum/skills/commando/deathsquad
	name = "Deathsquad"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_JTAC = SKILL_JTAC_BEGINNER,
	)

/datum/skills/spy
	name = "Spy"
	skills = list(
		SKILL_CQC = SKILL_CQC_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_JTAC = SKILL_JTAC_BEGINNER,
	)

/datum/skills/ninja
	name = "Ninja"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_JTAC = SKILL_JTAC_BEGINNER,
	)

/*
---------------------
MISCELLANEOUS
---------------------
*/

/datum/skills/mercenary
	name = "Mercenary"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_BEGINNER,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_JTAC = SKILL_JTAC_BEGINNER,
	)

/datum/skills/tank_crew
	name = "Vehicle Crewman"
	skills = list(
		SKILL_VEHICLE = SKILL_VEHICLE_CREWMAN,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/gladiator
	name = "Gladiator"
	skills = list(
		SKILL_CQC = SKILL_CQC_SKILLED,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_TRAINED,
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_NOVICE,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
	)

/datum/skills/gladiator/champion
	name = "Gladiator Champion"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_LEADERSHIP = SKILL_LEAD_TRAINED,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_TRAINED,
	)

/datum/skills/gladiator/champion/leader
	name = "Gladiator Leader"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER, //Spartacus!
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_MASTER,
	)

/datum/skills/yautja/warrior
	name = "Yautja Warrior"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_SURGERY = SKILL_SURGERY_EXPERT,
		SKILL_POLICE = SKILL_POLICE_SKILLED,
		SKILL_ANTAG = SKILL_ANTAG_HUNTER
	)

/datum/skills/dutch
	name = "Dutch"
	skills = list(
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_ENGINEER = SKILL_ENGINEER_ENGI,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_ENGI,
		SKILL_FIREARMS = SKILL_FIREARMS_TRAINED,
		SKILL_LEADERSHIP = SKILL_LEAD_EXPERT,
		SKILL_MEDICAL = SKILL_MEDICAL_TRAINED,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_EXPERT,
	)

/datum/skills/cultist_leader
	name = "Cultist Leader"
	skills = list(
		SKILL_FIREARMS = SKILL_FIREARMS_UNTRAINED,
		SKILL_CQC = SKILL_CQC_MASTER,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_SUPER,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MASTER,
		SKILL_ENGINEER = SKILL_ENGINEER_MASTER,
		SKILL_MEDICAL = SKILL_MEDICAL_MEDIC,
		SKILL_LEADERSHIP = SKILL_LEAD_MASTER,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_JTAC = SKILL_JTAC_MASTER,
	)

/datum/skills/everything //max it out
	name = "Ultra"
	skills = list(
		SKILL_CQC = SKILL_CQC_MAX,
		SKILL_MELEE_WEAPONS = SKILL_MELEE_MAX,
		SKILL_FIREARMS = SKILL_FIREARMS_MAX,
		SKILL_SPEC_WEAPONS = SKILL_SPEC_ALL,
		SKILL_ENDURANCE = SKILL_ENDURANCE_MAX,
		SKILL_ENGINEER = SKILL_ENGINEER_MAX,
		SKILL_CONSTRUCTION = SKILL_CONSTRUCTION_MAX,
		SKILL_LEADERSHIP = SKILL_LEAD_MAX,
		SKILL_MEDICAL = SKILL_MEDICAL_MAX,
		SKILL_SURGERY = SKILL_SURGERY_MAX,
		SKILL_RESEARCH = SKILL_RESEARCH_MAX,
		SKILL_ANTAG = SKILL_ANTAG_MAX,
		SKILL_PILOT = SKILL_PILOT_MAX,
		SKILL_POLICE = SKILL_POLICE_MAX,
		SKILL_POWERLOADER = SKILL_POWERLOADER_MAX,
		SKILL_VEHICLE = SKILL_VEHICLE_MAX,
		SKILL_JTAC = SKILL_JTAC_MAX
	)
