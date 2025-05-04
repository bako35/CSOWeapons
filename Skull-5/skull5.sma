#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

new g_hasskull5[33];
new g_skull5ammo[33];
new blood_spr[2];
new msgid_weaponlist;

new const wep_sg550 = ((1<<CSW_SG550));
new const gunshut_decals[] = { 41, 42, 43, 44, 45 }
new const g_vmodel[] = "models/v_skull5.mdl";
new const g_pmodel[] = "models/p_skull5.mdl";
new const g_wmodel[] = "models/w_skull5.mdl";
new const g_shootsound[] = "weapons/skull5.wav";

public plugin_init() {
	register_plugin("Skull 5", "1.0", "bako35");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_sg550", "fw_ReloadWeapon", 1); 
	RegisterHam(Ham_Item_Deploy, "weapon_sg550", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_sg550", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_sg550", "fw_ItemPostFrame");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	msgid_weaponlist = get_user_msgid("WeaponList");
	register_clcmd("gun", "give_skull5");
	register_clcmd("bakoweapon_skull5", "HookWeapon");
}

public client_connect(id){
	g_hasskull5[id] = false
}

public client_disconnect(id){
	g_hasskull5[id] = false
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound("weapons/skull5_boltpull.wav");
	precache_sound("weapons/skull5_clipin.wav");
	precache_sound("weapons/skull5_clipout.wav");
	precache_sound("weapons/skull5_draw.wav");
	precache_generic("sprites/skull/640hud7.spr");
	precache_generic("sprites/skull/640hud57.spr");
	precache_generic("sprites/bakoweapon_skull5.txt");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_sg550");
}

public give_skull5(id){
	new wpid
	if(is_user_alive(id) && !g_hasskull5[id]){
		if(user_has_weapon(id, CSW_SG550)){
			drop_weapon(id);
		}
		g_hasskull5[id] = true
		wpid = give_item(id, "weapon_sg550");
		UTIL_WeaponList(id, true);
		cs_set_weapon_ammo(wpid, 24);
		cs_set_user_bpammo(id, CSW_SG550, 200);
		replace_models(id);
		set_draw_animation(id, 2);
	}
}

public replace_models(id){
	new skull5 = read_data(2);
	if(g_hasskull5[id] && skull5 == CSW_SG550){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public death_player(id){
	g_hasskull5[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

stock set_draw_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_SG550 && g_hasskull5[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasskull5[id]){
		g_skull5ammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasskull5[id] && g_skull5ammo[id]){
		emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_shoot_animation(id, 3);
		UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasskull5[id]){
		set_reload_animation(id, 1);
		set_pdata_float(id, 46, 61/30.0, 4);
		set_pdata_float(id, 47, 61/30.0, 4);
		set_pdata_float(id, 48, 61/30.0, 4);
		set_pdata_float(id, 83, 61/30.0, 5);
	}
}

stock set_shoot_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_reload_animation(id, anim){
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

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++){
		if(wep_sg550 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasskull5[id]){
		set_draw_animation(id, 2);
	}
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_sg550.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_sg550", entity);
	
	if(g_hasskull5[owner] && pev_valid(wpn))
	{
		g_hasskull5[owner] = false;
		set_pev(wpn, pev_impulse, 43555);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43555)
	{
		g_hasskull5[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasskull5[id]){
		static iclipex = 24
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_SG550);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_SG550, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_SG550 && g_hasskull5[attacker])
	{
		SetHamParamFloat(4, damage + 13.0);
	}
}

stock UTIL_WeaponList(id, const bool: bEnabled)
{
	message_begin(MSG_ONE, msgid_weaponlist, _, id);
	write_string(bEnabled ? "bakoweapon_skull5" : "weapon_sg550");
	write_byte(4);
	write_byte(bEnabled ? 200 : 90);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(16);
	write_byte(13);
	write_byte(0);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
