#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hasminigun[33]
new g_minigunammo[33]
new fireready[33]
new blood_spr[2];
new minigun;

new const g_vmodel[] = "models/v_m134.mdl"
new const g_pmodel[] = "models/p_m134.mdl"
new const g_wmodel[] = "models/w_m134.mdl"
new const g_shootsound[] = "weapons/m134-1.wav"
new const gunshut_decals[] = {41, 42, 43, 44, 45}

public plugin_init() {
	register_plugin("M134 (Minigun)", "1.0", "bako35")
	register_clcmd("bakoweapon_m134", "HookWeapon");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	minigun = zp_register_extra_item("M134 Minigun", 0, ZP_TEAM_HUMAN|ZP_TEAM_SURVIVOR);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound("weapons/m134_clipoff.wav");
	precache_sound("weapons/m134_clipon.wav");
	precache_sound("weapons/m134_pinpull.wav");
	precache_sound("weapons/m134-2.wav");
	precache_sound("weapons/m134-0.wav");
	precache_generic("sprites/bakoweapon_m134.txt");
	precache_generic("sprites/640hud34.spr");
	precache_generic("sprites/640hud35.spr");
	precache_generic("sprites/minigun/640hud7.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m249");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasminigun[id] = false
}

public client_disconnect(id){
	g_hasminigun[id] = false
	UTIL_WeaponList(id, false);
	fireready[id] = true
}

public death_player(id){
	g_hasminigun[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
	fireready[read_data(2)] = true
}

public zp_extra_item_selected(id, itemid){
	if(itemid == minigun){
		give_minigun(id);
	}
}

public give_minigun(id){
	if(is_user_alive(id) && !g_hasminigun[id]){
		if(user_has_weapon(id, CSW_M249)){
			drop_weapon(id);
		}
		g_hasminigun[id] = true
		fireready[id] = true
		UTIL_WeaponList(id, true);
		new wpnid
		wpnid = give_item(id, "weapon_m249");
		cs_set_weapon_ammo(wpnid, 200);
		cs_set_user_bpammo(id, CSW_M249, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new m134 = read_data(2);
	if(g_hasminigun[id] && m134 == CSW_M249){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_M249) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasminigun[id]){
		static iclipex = 200
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_M249);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_M249, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_CmdStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_hasminigun[id]){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 1 || pev(id, pev_weaponanim) == 2){
			static weapon; weapon = fm_get_user_weapon_entity(id, CSW_M249)
			if(pev_valid(weapon)){
				set_pdata_float(weapon, 48, 2.0, 4)
			}
			set_weapon_animation(id, 6);
			emit_sound(id, CHAN_WEAPON, "weapons/m134-2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			fireready[id] = true
		}
		else if(pev(id, pev_weaponanim) == 5){
			fireready[id] = true
		}
	}
	return FMRES_HANDLED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M249 && g_hasminigun[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}


public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasminigun[id]){
		g_minigunammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasminigun[id] && g_minigunammo[id] && fireready[id]){
		set_pdata_int(weapon_entity, 51, g_minigunammo[id], 4);
		set_weapon_animation(id, 5);
		emit_sound(id, CHAN_WEAPON, "weapons/m134-0.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_float(id, 83, 1.0, 5);
		fireready[id] = false
	}
	else if(!fireready[id]){
		emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, random_num(1, 2));
		set_pdata_float(id, 83, 0.07, 5);
		UTIL_MakeBloodAndBulletHoles(id);
	}
	return HAM_SUPERCEDE
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage){
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_M249 && g_hasminigun[attacker] && fireready[attacker]){
		SetHamParamFloat(4, 0);
	}
}

public UTIL_MakeBloodAndBulletHoles(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	if(target > 0 && target <= get_maxplayers()){
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

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 24356)
	{
		g_hasminigun[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		fireready[id] = true;
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_m249.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m249", entity);
	
	if(g_hasminigun[owner] && pev_valid(wpn))
	{
		g_hasminigun[owner] = false;
		UTIL_WeaponList(owner, false);
		fireready[owner] = true
		set_pev(wpn, pev_impulse, 24356);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_m134" : "weapon_m249");
	write_byte(3);
	write_byte(200);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(4);
	write_byte(20);
	write_byte(0);
	message_end();
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
