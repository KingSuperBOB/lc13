//Oufi Association; the contract enforcement office
//Don't have good numbers yet but they'll do less DPS than average due to their gimmick
//Hit a enemy up close and you'll apply slowdown stacks to them, hit them from afar and you'll apply knockback but attack slower
//Apply enough stacks and use it inhand to begin a execution, have a lot of stacks and you'll do a upgraded execution
//Upgraded execution will have rending

/obj/item/ego_weapon/city/oufi_halberd
	name = "oufi association halberd"
	desc = "A halberd with a perfectly rectangular blade, used by the fixers of Öufi South Section 3 to enforce their contracts."
	special = "Everytime a enemy is hit by this weapon it will apply warning marks, warning marks will slow down the target and can be spent to trigger a execution. \
	Use weapon in-hand to trigger a execution on the next attack \
	If used at 2 range the weapon will attack slower and self-stun the user however it will apply knockback to enemies \
	This weapon amputates those it kills."
	icon_state = "olga" //SPRITES, I NEED YOU SPRITES
	inhand_icon_state = "oufihalberd"
	force = 35
	reach = 2
	attack_speed = 0.8
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	var/warningpower = 1
	var/finalwarning = 20
	var/executionwarning = 30
	var/RealOufi = FALSE
	var/Executing = FALSE
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 60,
	)

	hitsound = 'sound/weapons/ego/oufihalberd.ogg'
	attack_verb_continuous = list("attacks", "slashes", "slices", "tears", "lacerates", "rips", "dices", "cuts", "impales", "stabs", "gores")
	attack_verb_simple = list("attack", "slash", "slice", "tear", "lacerate", "rip", "dice", "cut", "impale", "stab", "gore")

//The whole weapons gimmick lies here
/obj/item/ego_weapon/city/oufi_halberd/attack(mob/living/target, mob/living/carbon/human/user)
	var/living = FALSE
	..()
	if(!CanUseEgo(user))
		return
	if(target.stat == DEAD)
		return
	else
		living = TRUE

	var/obj/item/clothing/suit/armor/ego_gear/city/oufi/uniform = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(uniform))
		RealOufi = TRUE
	else
		RealOufi = FALSE

	if(get_dist(target, user) > 1)//How the weapon acts if used at 2 range
		warningpower *= 2
		knockback = KNOCKBACK_LIGHT
		user.Immobilize(5)
		user.changeNext_move(CLICK_CD_MELEE*attack_speed*2)
	else
		warningpower = initial(warningpower)
		knockback = FALSE

	target.ApplyWarning(warningpower*(RealOufi*2))

	var/datum/status_effect/stacking/oufi_warning/warn

	for(target)
		if(warn.stacks >= executionwarning)
			user.say("I already gave you your final warning, prepare for execution sentencing.")
		else if(warn.stacks >= finalwarning)
			user.say("This is your first and final warning. No more.")

	if(target.stat == DEAD && living)
		Dismember(target)
		living = FALSE

//Press the button, redeem your warnings for a big execution
/obj/item/ego_weapon/city/oufi_halberd/attack_self(mob/living/carbon/human/user)
	..()
	Executing = TRUE
	to_chat(user, span_notice("You prepare your stance for a execution."))

/obj/item/ego_weapon/city/oufi_halberd/proc/Dismember(mob/living/target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/potential_target_list = list() //Grab all the limbs and see if one's worth taking
		var/actual_target_list = list()
		var/obj/item/bodypart/left_leg = H.get_bodypart(BODY_ZONE_L_LEG)
		potential_target_list += left_leg
		var/obj/item/bodypart/right_leg = H.get_bodypart(BODY_ZONE_R_LEG)
		potential_target_list += right_leg
		var/obj/item/bodypart/right_arm = H.get_bodypart(BODY_ZONE_R_ARM)
		potential_target_list += right_arm
		var/obj/item/bodypart/left_arm = H.get_bodypart(BODY_ZONE_L_ARM)
		potential_target_list += left_arm
		for(var/obj/item/bodypart/thepart in potential_target_list)
			if(thepart)
				actual_target_list += thepart
		var/obj/item/bodypart/removingpart = pick(actual_target_list)
		removingpart?.dismember()


// Oufi Shit
/datum/status_effect/stacking/oufi_warning
	id = "oufi_warning"
	alert_type = /atom/movable/screen/alert/status_effect/oufi_warning
	max_stacks = 30 //if Oufi are hitting you with close range itd take 8 hits to get here
	tick_interval = 15 SECONDS //Longer decay time than tremor as Oufi NEED to use it for their executions
	consumed_on_threshold = FALSE
	var/new_stack = TRUE

/atom/movable/screen/alert/status_effect/oufi_warning
	name = "Execution Warning"
	desc = "Your movement grows unsteady and sluggish as execution approaches."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "oufiwarning"

//Slowdown on stack like tremor, used up as fuel for Oufis execution
/datum/status_effect/stacking/oufi_warning/on_apply()
	. = ..()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/oufiwarning, multiplicative_slowdown = stacks * 0.5)

/datum/status_effect/stacking/oufi_warning/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/oufiwarning)
	return ..()

/datum/status_effect/stacking/oufi_warning/add_stacks(stacks)
	. = ..()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/oufiwarning, multiplicative_slowdown = stacks * 0.5)

/datum/status_effect/stacking/oufi_warning/can_have_status()
	return (owner.stat != DEAD || !(owner.status_flags & GODMODE))

// The Stack Decaying (this is the name for Canto 10 by the way)
/datum/status_effect/stacking/oufi_warning/tick()
	if(new_stack)
		new_stack = FALSE
	else
		qdel(src)

/datum/movespeed_modifier/oufiwarning
	multiplicative_slowdown = 0
	variable = TRUE

/mob/living/proc/ApplyWarning(stacks)
	var/datum/status_effect/stacking/oufi_warning/warn = src.has_status_effect(/datum/status_effect/stacking/oufi_warning)
	if(!warn)
		src.apply_status_effect(/datum/status_effect/stacking/oufi_warning, stacks)
	else
		warn.add_stacks(stacks)
