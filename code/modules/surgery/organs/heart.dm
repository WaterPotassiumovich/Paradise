/obj/item/organ/internal/heart
	name = "heart"
	icon_state = "heart-on"
	parent_organ_zone = BODY_ZONE_CHEST
	slot = INTERNAL_ORGAN_HEART
	origin_tech = "biotech=5"
	var/beating = TRUE
	dead_icon = "heart-off"
	var/icon_base = "heart"


/obj/item/organ/internal/heart/update_icon_state()
	if(beating)
		icon_state = "[icon_base]-on"
	else
		icon_state = "[icon_base]-off"


/obj/item/organ/internal/heart/remove(mob/living/carbon/human/target, special = ORGAN_MANIPULATION_DEFAULT)
	if(!special)
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 12 SECONDS)
	. = ..()


/obj/item/organ/internal/heart/emp_act(intensity)
	if(!is_robotic() || emp_proof)
		return
	Stop()


/obj/item/organ/internal/heart/necrotize(silent = FALSE)
	if(..())
		Stop()


/obj/item/organ/internal/heart/attack_self(mob/user)
	..()
	if(is_dead())
		to_chat(user, span_warning("You can't restart a dead heart."))
		return
	if(!beating)
		Restart()
		addtimer(CALLBACK(src, PROC_REF(stop_if_unowned)), 80)


/obj/item/organ/internal/heart/safe_replace(mob/living/carbon/human/target)
	Restart()
	..()


/obj/item/organ/internal/heart/proc/stop_if_unowned()
	if(!owner)
		Stop()


/obj/item/organ/internal/heart/proc/Stop()
	beating = FALSE
	update_icon()
	return TRUE


/obj/item/organ/internal/heart/proc/Restart()
	beating = TRUE
	update_icon()
	return TRUE


/obj/item/organ/internal/heart/prepare_eat()
	var/obj/S = ..()
	S.icon_state = dead_icon
	return S


/obj/item/organ/internal/heart/cursed
	name = "cursed heart"
	desc = "it needs to be pumped..."
	icon_state = "cursedheart-off"
	icon_base = "cursedheart"
	origin_tech = "biotech=6"
	actions_types = list(/datum/action/item_action/organ_action/cursed_heart)
	var/last_pump = 0
	var/pump_delay = 30 //you can pump 1 second early, for lag, but no more (otherwise you could spam heal)
	var/blood_loss = 100 //600 blood is human default, so 5 failures (below 122 blood is where humans die because reasons?)

	//How much to heal per pump, negative numbers would HURT the player
	var/heal_brute = 0
	var/heal_burn = 0
	var/heal_oxy = 0


/obj/item/organ/internal/heart/cursed/attack(mob/living/carbon/human/target, mob/living/user, params, def_zone, skip_attack_anim = FALSE)
	if(target != user || !ishuman(target))
		return ..()

	if(HAS_TRAIT(user, TRAIT_NO_BLOOD))
		to_chat(user, span_userdanger("The [name] is not compatible with your form!"))
		return ATTACK_CHAIN_PROCEED

	if(!user.temporarily_remove_item_from_inventory(src))
		return .

	playsound(user, 'sound/effects/singlebeat.ogg', 40, TRUE)
	insert(user)
	return ATTACK_CHAIN_BLOCKED_ALL


/obj/item/organ/internal/heart/cursed/on_life()
	if(world.time > (last_pump + pump_delay))
		if(ishuman(owner) && owner.client) //While this entire item exists to make people suffer, they can't control disconnects.
			var/mob/living/carbon/human/H = owner
			if(!HAS_TRAIT(H, TRAIT_NO_BLOOD))
				H.blood_volume = max(H.blood_volume - blood_loss, 0)
				to_chat(H, span_userdanger("You have to keep pumping your blood!"))
				if(H.client)
					H.client.color = "red" //bloody screen so real
		else
			last_pump = world.time //lets be extra fair *sigh*


/obj/item/organ/internal/heart/cursed/insert(mob/living/carbon/M, special = ORGAN_MANIPULATION_DEFAULT)
	. = ..()
	if(owner)
		to_chat(owner, span_userdanger("Your heart has been replaced with a cursed one, you have to pump this one manually otherwise you'll die!"))


/datum/action/item_action/organ_action/cursed_heart
	name = "pump your blood"


//You are now brea- pumping blood manually
/datum/action/item_action/organ_action/cursed_heart/Trigger(left_click = TRUE)
	. = ..()
	if(. && istype(target, /obj/item/organ/internal/heart/cursed))
		var/obj/item/organ/internal/heart/cursed/cursed_heart = target

		if(world.time < (cursed_heart.last_pump + (cursed_heart.pump_delay - 10))) //no spam
			owner.balloon_alert(owner, "слишком рано")
			return

		cursed_heart.last_pump = world.time
		playsound(owner,'sound/effects/singlebeat.ogg',40,1)
		owner.balloon_alert(owner, "твоё сердце бьется")

		var/mob/living/carbon/human/H = owner
		if(istype(H) && !HAS_TRAIT(H, TRAIT_NO_BLOOD))
			if(!HAS_TRAIT(H, TRAIT_NO_BLOOD_RESTORE))
				H.blood_volume = min(H.blood_volume + cursed_heart.blood_loss * 0.5, BLOOD_VOLUME_NORMAL)

			if(owner.client)
				owner.client.color = ""

			var/update = NONE
			update |= H.heal_overall_damage(cursed_heart.heal_brute, cursed_heart.heal_burn, updating_health = FALSE, affect_robotic = TRUE)
			update |= H.heal_damage_type(cursed_heart.heal_oxy, OXY, updating_health = FALSE)
			if(update)
				H.updatehealth()


/obj/item/organ/internal/heart/cybernetic
	name = "cybernetic heart"
	desc = "An electronic device designed to mimic the functions of an organic human heart. Offers no benefit over an organic heart other than being easy to make."
	icon_state = "heart-c-on"
	icon_base = "heart-c"
	dead_icon = "heart-c-off"
	status = ORGAN_ROBOT
	pickup_sound = 'sound/items/handling/component_pickup.ogg'
	drop_sound = 'sound/items/handling/component_drop.ogg'


/obj/item/organ/internal/heart/cybernetic/upgraded
	name = "upgraded cybernetic heart"
	desc = "A more advanced version of a cybernetic heart. Grants the user additional stamina and heart stability, but the electronics are vulnerable to shock."
	icon_state = "heart-c-u-on"
	icon_base = "heart-c-u"
	dead_icon = "heart-c-u-off"
	var/emagged = FALSE
	var/attempted_restart = FALSE


/obj/item/organ/internal/heart/cybernetic/upgraded/insert(mob/living/carbon/target, special)
	. = ..()

	if(HAS_TRAIT(target, TRAIT_ADVANCED_CYBERIMPLANTS))
		target.stam_regen_start_modifier *= 0.5
		ADD_TRAIT(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src))


/obj/item/organ/internal/heart/cybernetic/upgraded/remove(mob/living/carbon/human/target, special)
	if(HAS_TRAIT_FROM(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src)))
		target.stam_regen_start_modifier /= 0.5
		REMOVE_TRAIT(target, TRAIT_CYBERIMP_IMPROVED, UNIQUE_TRAIT_SOURCE(src))

	. = ..()


/obj/item/organ/internal/heart/cybernetic/upgraded/on_life()
	if(!ishuman(owner))
		return

	if(!is_dead() && !attempted_restart && !beating)
		to_chat(owner, span_warning("Your [name] detects a cardiac event and attempts to return to its normal rhythm!"))
		if(prob(20) && emagged)
			attempted_restart = TRUE
			Restart()
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] returns to its normal rhythm!")), 30)
			addtimer(CALLBACK(src, PROC_REF(recharge)), 200)
		else if(prob(10))
			attempted_restart = TRUE
			Restart()
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] returns to its normal rhythm!")), 30)
			addtimer(CALLBACK(src, PROC_REF(recharge)), 300)
		else
			attempted_restart = TRUE
			if(emagged)
				addtimer(CALLBACK(src, PROC_REF(recharge)), 200)
			else
				addtimer(CALLBACK(src, PROC_REF(recharge)), 300)
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] fails to return to its normal rhythm!")), 30)

	if(!is_dead() && !attempted_restart && owner.HasDisease(/datum/disease/critical/heart_failure))
		to_chat(owner, span_warning("Your [name] detects a cardiac event and attempts to return to its normal rhythm!"))
		if(prob(40) && emagged)
			attempted_restart = TRUE
			for(var/datum/disease/critical/heart_failure/HF in owner.diseases)
				HF.cure()
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] returns to its normal rhythm!")), 30)
			addtimer(CALLBACK(src, PROC_REF(recharge)), 200)
		else if(prob(25))
			attempted_restart = TRUE
			for(var/datum/disease/critical/heart_failure/HF in owner.diseases)
				HF.cure()
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] returns to its normal rhythm!")), 30)
			addtimer(CALLBACK(src, PROC_REF(recharge)), 200)
		else
			attempted_restart = TRUE
			if(emagged)
				addtimer(CALLBACK(src, PROC_REF(recharge)), 200)
			else
				addtimer(CALLBACK(src, PROC_REF(recharge)), 300)
			addtimer(CALLBACK(src, PROC_REF(message_to_owner), owner, span_warning("Your [name] fails to return to its normal rhythm!")), 30)

	if(!is_dead())
		var/boost = emagged ? 2 : 1
		owner.AdjustDrowsy(-8 SECONDS * boost)
		owner.AdjustParalysis(-2 SECONDS * boost)
		owner.AdjustStunned(-2 SECONDS * boost)
		owner.AdjustWeakened(-2 SECONDS * boost)
		owner.SetSleeping(0)
		owner.adjustStaminaLoss(-7 * boost)


/obj/item/organ/internal/heart/cybernetic/upgraded/proc/message_to_owner(mob/M, message)
	to_chat(M, message)


/obj/item/organ/internal/heart/cybernetic/upgraded/proc/recharge()
	attempted_restart = FALSE


/obj/item/organ/internal/heart/cybernetic/upgraded/emag_act(mob/user)
	if(!emagged)
		add_attack_logs(user, src, "emagged")
		if(user)
			to_chat(user, span_warning("You disable the safeties on [src]"))
		emagged = TRUE
	else
		add_attack_logs(user, src, "un-emagged")
		if(user)
			to_chat(user, span_warning("You re-enable the safeties on [src]"))
		emagged = FALSE


/obj/item/organ/internal/heart/cybernetic/upgraded/emp_act(severity)
	..()

	if(emp_proof)
		return

	if(HAS_TRAIT(owner, TRAIT_ADVANCED_CYBERIMPLANTS))
		Stop()
	else
		necrotize()


/obj/item/organ/internal/heart/cybernetic/upgraded/shock_organ(intensity)
	if(!ishuman(owner))
		return
	if(emp_proof)
		return
	intensity = min(intensity, 100)
	var/numHigh = round(intensity / 5)
	var/numMid = round(intensity / 10)
	var/numLow = round(intensity / 20)
	if(emagged && !is_dead())
		if(prob(numHigh))
			to_chat(owner, span_warning("Your [name] spasms violently!"))
			owner.adjustBruteLoss(numHigh)
		if(prob(numHigh))
			to_chat(owner, span_warning("Your [name] shocks you painfully!"))
			owner.adjustFireLoss(numHigh)
		if(prob(numMid))
			to_chat(owner, span_warning("Your [name] lurches awkwardly!"))
			var/datum/disease/critical/heart_failure/D = new
			D.Contract(owner)
		if(prob(numMid))
			to_chat(owner, span_danger("Your [name] stops beating!"))
			Stop()
		if(prob(numLow))
			to_chat(owner, span_danger("Your [name] shuts down!"))
			necrotize()
	else if(!emagged && !is_dead())
		if(prob(numMid))
			to_chat(owner, span_warning("Your [name] spasms violently!"))
			owner.adjustBruteLoss(numMid)
		if(prob(numMid))
			to_chat(owner, span_warning("Your [name] shocks you painfully!"))
			owner.adjustFireLoss(numMid)
		if(prob(numLow))
			to_chat(owner, span_warning("Your [name] lurches awkwardly!"))
			var/datum/disease/critical/heart_failure/D = new
			D.Contract(owner)
