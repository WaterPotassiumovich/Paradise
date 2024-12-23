/*
/mob/living/carbon/human/say(message, verb = "says", sanitize = TRUE, ignore_speech_problems = FALSE, ignore_atmospherics = FALSE, ignore_languages = FALSE)
	..(message, sanitize = sanitize, ignore_speech_problems = ignore_speech_problems, ignore_atmospherics = ignore_atmospherics)	//ohgod we should really be passing a datum here.
*/

/mob/living/carbon/human/GetAltName()
	if(name != GetVoice())
		return " (as [get_id_name("Unknown")])"
	return ..()


/mob/living/carbon/human/say_understands(mob/other, datum/language/speaking = null)
	if(dna?.species?.can_understand(other))
		return TRUE

	//These only pertain to common. Languages are handled by mob/say_understands()
	if(!speaking)
		if(isnymph(other) && LAZYLEN(other.languages) >= 2)	//They've sucked down some blood and can speak common now.
			return TRUE
		if(issilicon(other) || isbot(other) || isbrain(other) || isslime(other))
			return TRUE

	return ..()


/mob/living/carbon/human/proc/HasVoiceChanger()
	for(var/obj/item/gear in list(wear_mask, wear_suit, head))
		if(!gear)
			continue

		var/obj/item/voice_changer/changer = locate() in gear
		if(changer?.active)
			if(changer.voice)
				return changer.voice
			else if(wear_id)
				var/obj/item/card/id/idcard = wear_id.GetID()
				if(istype(idcard))
					return idcard.registered_name

	return FALSE


/mob/living/carbon/human/proc/HasTTSVoiceChanger()
	for(var/obj/item/gear in list(wear_mask, wear_suit, head))
		if(!gear)
			continue

		var/obj/item/voice_changer/changer = locate() in gear
		if(changer?.active && changer.tts_voice)
			return changer.tts_voice

	return FALSE


/mob/living/carbon/human/GetVoice()
	var/has_changer = HasVoiceChanger()

	if(has_changer)
		return has_changer

	var/datum/antagonist/changeling/cling = mind?.has_antag_datum(/datum/antagonist/changeling)
	if(cling?.mimicking)
		return cling.mimicking

	if(GetSpecialVoice())
		return GetSpecialVoice()

	return real_name


/mob/living/carbon/human/GetTTSVoice()
	var/has_changer_tts = HasTTSVoiceChanger()

	if(has_changer_tts)
		return has_changer_tts

	var/datum/antagonist/changeling/cling = mind?.has_antag_datum(/datum/antagonist/changeling)
	if(cling?.tts_mimicking)
		return cling.tts_mimicking

	if(GetSpecialTTSVoice())
		return GetSpecialTTSVoice()

	return dna.tts_seed_dna


/mob/living/carbon/human/IsVocal()
	var/obj/item/organ/internal/cyberimp/brain/speech_translator/translator = locate() in internal_organs
	if(translator?.active)
		return TRUE
	if(HAS_TRAIT(src, TRAIT_MUTE))
		return FALSE
	// how do species that don't breathe talk? magic, that's what.
	var/breathes = !HAS_TRAIT(src, TRAIT_NO_BREATH)
	var/obj/item/organ/internal/lungs = get_organ_slot(INTERNAL_ORGAN_LUNGS)
	if((breathes && !lungs) || (breathes && lungs && lungs.is_dead()))
		return FALSE
	if(mind)
		return !mind.miming
	return TRUE

/mob/living/carbon/human/cannot_speak_loudly()
	return getOxyLoss() > 10 || AmountLoseBreath() >= 8 SECONDS


/mob/living/carbon/human/proc/SetSpecialVoice(new_voice)
	if(new_voice)
		special_voice = new_voice


/mob/living/carbon/human/proc/UnsetSpecialVoice()
	special_voice = ""


/mob/living/carbon/human/proc/GetSpecialVoice()
	return special_voice


/mob/living/carbon/human/proc/SetSpecialTTSVoice(new_voice)
	if(new_voice)
		special_tts_voice = new_voice


/mob/living/carbon/human/proc/UnsetSpecialTTSVoice()
	special_tts_voice = ""


/mob/living/carbon/human/proc/GetSpecialTTSVoice()
	return special_tts_voice


/mob/living/carbon/human/handle_speech_problems(list/message_pieces, verb)
	var/span = ""

	var/obj/item/organ/internal/cyberimp/brain/speech_translator/translator = locate() in internal_organs
	if(translator?.active && !HAS_TRAIT(src, TRAIT_MUTE))
		span = translator.speech_span
		for(var/datum/multilingual_say_piece/S in message_pieces)
			S.message = "<span class='[span]'>[S.message]</span>"
		verb = translator.speech_verb
		return list("verb" = verb)

	if(HAS_TRAIT(src, TRAIT_COMIC) \
		|| (locate(/obj/item/organ/internal/cyberimp/brain/clown_voice) in internal_organs) \
		|| HAS_TRAIT(src, TRAIT_JESTER))
		span = "sans"

	if(HAS_TRAIT(src, TRAIT_WINGDINGS))
		span = "wingdings"

	var/list/parent = ..()
	verb = parent["verb"]

	for(var/datum/multilingual_say_piece/S in message_pieces)
		if(S.speaking?.flags & NO_STUTTER)
			continue

		if(HAS_TRAIT(src, TRAIT_MUTE))
			S.message = ""

		if(istype(wear_mask, /obj/item/clothing/mask/horsehead))
			var/obj/item/clothing/mask/horsehead/hoers = wear_mask
			if(hoers.voicechange)
				S.message = pick("NEEIIGGGHHHH!", "NEEEIIIIGHH!", "NEIIIGGHH!", "HAAWWWWW!", "HAAAWWW!")

		if(dna)
			for(var/datum/dna/gene/gene as anything in GLOB.dna_genes)
				if(gene.is_active(src))
					S.message = gene.OnSay(src, S.message)

		var/braindam = getBrainLoss()
		if(braindam >= 60)
			if(prob(braindam / 4))
				S.message = stutter(S.message)
				verb = "gibbers"
			if(prob(braindam))
				S.message = uppertext(S.message)
				verb = "yells loudly"

		if(span && (length(S.message)))
			S.message = "<span class='[span]'>[S.message]</span>"

	if(wear_mask)
		var/speech_verb_when_masked = wear_mask.change_speech_verb()
		if(speech_verb_when_masked)
			verb = speech_verb_when_masked

	return list("verb" = verb)


/mob/living/carbon/human/handle_message_mode(message_mode, list/message_pieces, verb, used_radios)
	switch(message_mode)
		if("intercom")
			for(var/obj/item/radio/intercom/I in view(1, src))
				spawn(0)
					I.talk_into(src, message_pieces, null, verb)
				used_radios += I

		if("headset")
			var/obj/item/radio/R = null
			if(isradio(l_ear))
				R = l_ear
				used_radios += R
				if(R.talk_into(src, message_pieces, null, verb))
					return FALSE

			if(isradio(r_ear))
				R = r_ear
				used_radios += R
				if(R.talk_into(src, message_pieces, null, verb))
					return FALSE

		if("right ear")
			var/obj/item/radio/R
			if(isradio(r_hand))
				R = r_hand
			else if(isradio(r_ear))
				R = r_ear
			if(R)
				used_radios += R
				R.talk_into(src, message_pieces, null, verb)

		if("left ear")
			var/obj/item/radio/R
			if(isradio(l_hand))
				R = l_hand
			else if(isradio(l_ear))
				R = l_ear
			if(R)
				used_radios += R
				R.talk_into(src, message_pieces, null, verb)

		if("whisper")
			whisper_say(message_pieces)
			return TRUE

		else
			if(message_mode)
				if(isradio(l_ear))
					used_radios += l_ear
					if(l_ear.talk_into(src, message_pieces, message_mode, verb))
						return FALSE

				if(isradio(r_ear))
					used_radios += r_ear
					if(r_ear.talk_into(src, message_pieces, message_mode, verb))
						return FALSE


/mob/living/carbon/human/handle_speech_sound()
	var/list/returns[3]
	if(dna.species.speech_sounds && prob(dna.species.speech_chance))
		returns[1] = sound(pick(dna.species.speech_sounds))
		returns[2] = 50
		returns[3] = get_age_pitch()
	return returns


/mob/living/carbon/human/binarycheck()
	. = FALSE
	var/obj/item/radio/headset/R
	if(istype(l_ear, /obj/item/radio/headset))
		R = l_ear
		if(R.translate_binary)
			. = TRUE

	if(istype(r_ear, /obj/item/radio/headset))
		R = r_ear
		if(R.translate_binary)
			. = TRUE


/mob/living/carbon/human/proc/forcesay(list/append)
	if(stat != CONSCIOUS || !client)
		return

	var/modified = FALSE	//has the text been modified yet?
	var/temp = winget(client, "input", "text")
	if(findtextEx(temp, "Say \"", 1, 7) && length(temp) > 5)	//case sensitive means

		temp = replacetext(temp, ";", "")	//general radio

		if(findtext(trim_left(temp), ":", 6, 7))	//dept radio
			temp = copytext(trim_left(temp), 8)
			modified = TRUE

			if(!modified)
				temp = copytext(trim_left(temp), 6)	//normal speech
				modified = TRUE

			while(findtext(trim_left(temp), ":", 1, 2))	//dept radio again (necessary)
				temp = copytext(trim_left(temp), 3)

			if(findtext(temp, "*", 1, 2))	//emotes
				return
			temp = copytext(trim_left(temp), 1, rand(5,8))

			var/trimmed = trim_left(temp)
			if(length(trimmed))
				if(append)
					temp += pick(append)

				say(temp)

			winset(client, "input", "text=[null]")

