#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <zombieplague>

new g_hasstarchaserar[33];
new g_starchaserarammo[33];
new g_secattackready[33];
new blood_spr[2];
new trail;
new g_exp;
new g_death;
new starchaserar;
new cvar_exp_damage;
new cvar_ammo;
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_starchaserar.mdl"
new const g_pmodel[] = "models/p_starchaserar.mdl"
new const g_wmodel[] = "models/w_starchaserar.mdl"
new const g_shootsound[] = "weapons/starchaserar-1.wav"
new const g_shootsound2[] = "weapons/starchaserar-2.wav"

public plugin_init() {
	register_plugin("Star Chaser AR", "1.0", "bako35");
	register_clcmd("bakoweapon_starchaserar", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Item_PostFrame, "weapon_aug", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_aug", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	g_death = get_user_msgid("DeathMsg");
	cvar_exp_damage = register_cvar("starchaser_exp_damage", "5.0");
	cvar_ammo = register_cvar("starchaser_ammo", "35");
	starchaserar = zp_register_extra_item("Star Chaser AR", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound(g_shootsound2);
	precache_sound("weapons/starchaserar_boltpull.wav");
	precache_sound("weapons/starchaserar_clipin.wav");
	precache_sound("weapons/starchaserar_clipout.wav");
	precache_sound("weapons/starchasersr_exp.wav");
	precache_generic("sprites/cso/640hud19.spr");
	precache_generic("sprites/640hud178.spr");
	precache_generic("sprites/bakoweapon_starchaserar.txt");
	g_exp = precache_model("sprites/ef_starchasersr_explosion.spr");
	trail = precache_model("sprites/ef_starchasersr_line.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_aug");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasstarchaserar[id] = false
	g_secattackready[id] = true
}

public client_disconnect(id){
	g_hasstarchaserar[id] = false
	g_secattackready[id] = true
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasstarchaserar[read_data(2)] = false
	g_secattackready[read_data(2)] = true
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hasstarchaserar[id] = false
	g_secattackready[id] = true
	UTIL_WeaponList(id, false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == starchaserar){
		give_starchaserar(id);
	}
}

public give_starchaserar(id){
	if(is_user_alive(id) && !g_hasstarchaserar[id]){
		if(user_has_weapon(id, CSW_AUG)){
			drop_weapon(id);
		}
		g_hasstarchaserar[id] = true
		g_secattackready[id] = true
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_aug");
		cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_ammo));
		cs_set_user_bpammo(id, CSW_AUG, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new starchaserar = read_data(2);
	if(g_hasstarchaserar[id] && starchaserar == CSW_AUG){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_AUG) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasstarchaserar[id]){
		static iclipex
		iclipex = get_pcvar_num(cvar_ammo)
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_AUG);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_AUG, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_AUG && g_hasstarchaserar[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasstarchaserar[id] && !g_secattackready[id]){
		g_starchaserarammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	else if(g_secattackready[id]){
		g_starchaserarammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasstarchaserar[id] && g_starchaserarammo[id] && !g_secattackready[id]){
		emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, random_num(3, 5));
		UTIL_MakeBloodAndBulletHoles(id);
	}
	else if(g_hasstarchaserar[id] && g_starchaserarammo[id] && g_secattackready[id]){
		new data[1]
		data[0] = id
		emit_sound(id, CHAN_ITEM, g_shootsound2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, random_num(3, 5));
		//laser(id);
		UTIL_Explode(id);
		g_secattackready[id] = false
		set_task(1.0, "star_ready", .parameter = data, .len = 1);
	}
}

public star_ready(data[]){
	new id
	id = data[0]
	g_secattackready[id] = true
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage){
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_AUG && g_hasstarchaserar[attacker]){
		SetHamParamFloat(4, damage - 10);
	}
}

public UTIL_Explode(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3], fPlayer[3];
	pev(id, pev_origin, fStart);
	pev(id, pev_origin, fPlayer);
		
	velocity_by_aim(id, 64, fVel);
		
	fStart[0] = float(aimOrigin[0]);
	fStart[1] = float(aimOrigin[1]);
	fStart[2] = float(aimOrigin[2]);
	fEnd[0] = fStart[0]+fVel[0];
	fEnd[1] = fStart[1]+fVel[1];
	fEnd[2] = fStart[2]+fVel[2];
		
	new res;
	engfunc(EngFunc_TraceLine, fStart, fEnd, DONT_IGNORE_MONSTERS, target, res);
	get_tr2(res, TR_vecEndPos, fRes);
		
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fStart[0])
	engfunc(EngFunc_WriteCoord, fStart[1])
	engfunc(EngFunc_WriteCoord, fStart[2])
	write_short(g_exp)
	write_byte(8)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,fPlayer[0]);
	engfunc(EngFunc_WriteCoord,fPlayer[1]);
	engfunc(EngFunc_WriteCoord,fPlayer[2]);
	engfunc(EngFunc_WriteCoord,fStart[0]); //Random
	engfunc(EngFunc_WriteCoord,fStart[1]); //Random
	engfunc(EngFunc_WriteCoord,fStart[2]); //Random
	write_short(trail);
	write_byte(0);
	write_byte(100);
	write_byte(10);	//Life
	write_byte(100);//Width
	write_byte(0);	//wave
	write_byte(255); // r
	write_byte(255); // g
	write_byte(255); // b
	write_byte(255);
	write_byte(255);
	message_end();
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, 75.0)) != 0){
		if(!is_user_alive(victim) || !zp_get_user_zombie(victim)){
			continue
		}
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHam(Ham_TakeDamage, victim, 0, id, get_pcvar_float(cvar_exp_damage), DMG_BLAST|DMG_NEVERGIB);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(victim) <= 0){
			SendDeathMsg(id, victim, 0, "aug");
		}
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 121212121)
	{
		g_hasstarchaserar[id] = true;
		g_secattackready[id] = true
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_aug.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_aug", entity);
	
	if(g_hasstarchaserar[owner] && pev_valid(wpn))
	{
		g_hasstarchaserar[owner] = false;
		g_secattackready[owner] = true
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 121212121);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock UTIL_MakeBloodAndBulletHoles(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	if(target > 0 && target <= get_maxplayers() && zp_get_user_zombie(id)){
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3];
		pev(id, pev_origin, fStart);
		
		velocity_by_aim(id, 64, fVel);
		
		fStart[0] = float(aimOrigin[0]);
		fStart[1] = float(aimOrigin[1]);
		fStart[2] = float(aimOrigin[2]);
		fEnd[0] = fStart[0]+fVel[0];
		fEnd[1] = fStart[1]+fVel[1];
		fEnd[2] = fStart[2]+fVel[2];
		
		new res;
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res);
		get_tr2(res, TR_vecEndPos, fRes);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BLOODSPRITE);
		write_coord(floatround(fStart[0]));
		write_coord(floatround(fStart[1]));
		write_coord(floatround(fStart[2]));
		write_short(blood_spr[1]);
		write_short(blood_spr[0]);
		write_byte(70);
		write_byte(random_num(1,2));
		message_end();
		
		
	} 
	else if(!is_user_connected(target)){
		if(target){
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_DECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(gunshut_decals[random_num(0, sizeof gunshut_decals -1)]);
			write_short(target);
			message_end();
		} 
		else{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_WORLDDECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(gunshut_decals[random_num(0, sizeof gunshut_decals -1)]);
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2]);
		write_short(id);
		write_byte(gunshut_decals[random_num(0, sizeof gunshut_decals -1 )]);
		message_end();
	}
}

stock SendDeathMsg(attacker, victim, headshot, const KillersWeapon[]){ // Sends death message
	static bool:kwpn[64]
	format(kwpn, 63, "%s", KillersWeapon);
	
	message_begin(MSG_BROADCAST, g_death)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag
	write_string(kwpn) // killer's weapon
	message_end()
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_starchaserar" : "weapon_aug");
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(14)
	write_byte(8)
	write_byte(0)
	message_end();
}
