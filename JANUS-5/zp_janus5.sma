#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombieplague>

new g_hasjanus5[33];
new g_janus5ammo[33];
new g_ready[33];
new g_janusmode[33];
new g_sattack[33];
new g_sectime[33];
new blood_spr[2];
new msgid_ammox;
new janus5
new cvar_janus5shots;

new const gunshut_decals[] = {41, 42, 43, 44, 45}
new const g_vmodel[] = "models/v_janusmk5.mdl"
new const g_pmodel[] = "models/p_janusmk5.mdl"
new const g_wmodel[] = "models/w_janusmk5.mdl"
new const g_shootsound[] = "weapons/janusmk5-1.wav"
new const g_shootsound2[] = "weapons/janusmk5-12.wav"
new const g_shootsoundjanusmode[] = "weapons/janusmk5-2.wav"

public plugin_init() {
	register_plugin("JANUS-5", "1.0", "bako35");
	register_clcmd("bakoweapon_janusmk5", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_CmdStart, "fw_CmdStart");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "fw_SecondaryAttack");
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "fw_DeployPost", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m4a1", "fw_WeaponIdle");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Spawn, "player", "fw_Spawn");
	msgid_ammox = get_user_msgid("AmmoX");
	janus5 = zp_register_extra_item("JANUS 5", 0, ZP_TEAM_HUMAN);
	cvar_janus5shots = register_cvar("zp_janus5_shots", "65");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound(g_shootsound2);
	precache_sound(g_shootsoundjanusmode);
	precache_sound("weapons/change1_ready.wav");
	precache_sound("weapons/janusmk5_boltpull.wav");
	precache_sound("weapons/janusmk5_change1.wav");
	precache_sound("weapons/janusmk5_change2.wav");
	precache_sound("weapons/janusmk5_clipin.wav");
	precache_sound("weapons/janusmk5_clipout.wav");
	precache_sound("weapons/janusmk5_draw1.wav");
	precache_generic("sprites/cso/640hud12.spr");
	precache_generic("sprites/640hud98.spr");
	precache_generic("sprites/cso/640hud7.spr");
	precache_generic("sprites/bakoweapon_janusmk5.txt");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m4a1");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasjanus5[id] = false
	g_janusmode[id] = false
	UTIL_WeaponList(id, false);
}

public client_disconnect(id){
	if(g_janusmode[id]){
		remove_task(id);
	}
	g_hasjanus5[id] = false
	g_janusmode[id] = false
	g_ready[id] = false
	UTIL_WeaponList(id, false);
	g_sattack[id] = 0
	set_sec_ammo(id, 0);
}

public death_player(id){
	if(g_janusmode[read_data(2)]){
		remove_task(id);
	}
	g_hasjanus5[read_data(2)] = false
	g_janusmode[read_data(2)] = false
	g_ready[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
	g_sattack[read_data(2)] = 0
	set_sec_ammo(read_data(2), 0);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == janus5){
		give_janus5(id);
	}
}

public give_janus5(id){
	if(is_user_alive(id) && !g_hasjanus5[id]){
		if(user_has_weapon(id, CSW_M4A1)){
			drop_weapon(id)
		}
		g_hasjanus5[id] = true
		g_janusmode[id] = false
		g_ready[id] = false
		g_sattack[id] = 0
		give_item(id, "weapon_m4a1");
		UTIL_WeaponList(id, true);
		cs_set_user_bpammo(id, CSW_M4A1, 200);
		set_sec_ammo(id, 0);
		replace_models(id);
	}
}

public replace_models(id){
	new janus5 = read_data(2);
	if(g_hasjanus5[id] && janus5 == CSW_M4A1){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++){
		if(((1<<CSW_M4A1)) & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5)
	if(g_hasjanus5[id]){
		g_janus5ammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasjanus5[id] && g_janus5ammo[id]){
		if(g_sattack[id] < get_pcvar_num(cvar_janus5shots)){
			sec_attack(id);
		}
		if(g_janusmode[id]){
			emit_sound(id, CHAN_WEAPON, g_shootsoundjanusmode, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_weapon_animation(id, random_num(8, 10));
			cs_set_weapon_ammo(weapon_entity, cs_get_weapon_ammo(weapon_entity) + 1);
		}
		else{
			emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		if(!g_ready[id] && !g_janusmode[id]){
			set_weapon_animation(id, 3);
		}
		else if(g_ready[id] && !g_janusmode[id]){
			set_weapon_animation(id, 4);
		}
		UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_SecondaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5)
	if(g_hasjanus5[id] && g_ready[id] && !g_janusmode[id] && g_sattack[id] >= get_pcvar_num(cvar_janus5shots)){
		g_janusmode[id] = true
		set_weapon_animation(id, 5);
		set_pdata_float(id, 46, 61/30.0, 4);
		set_pdata_float(id, 47, 61/30.0, 4);
		set_pdata_float(id, 48, 61/30.0, 4);
		set_pdata_float(id, 83, 61/30.0, 5);
		g_sectime[id] = 0
		set_task(1.0, "sectime",id, _, _, "b");
		return HAM_SUPERCEDE
	}
	else{
		return HAM_SUPERCEDE
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M4A1 && g_hasjanus5[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasjanus5[id] && !g_janusmode[id] && !g_ready[id]){
		set_weapon_animation(id, 1);
	}
	else if(g_hasjanus5[id] && !g_janusmode[id] && g_ready[id]){
		set_weapon_animation(id, 13);
	}
		set_pdata_float(id, 46, 101/30.0, 4);
		set_pdata_float(id, 47, 101/30.0, 4);
		set_pdata_float(id, 48, 101/30.0, 4);
		set_pdata_float(id, 83, 101/30.0, 5);
		return HAM_SUPERCEDE
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasjanus5[id] && !g_janusmode[id] && !g_ready[id]){
		set_weapon_animation(id, 2);
	}
	else if(g_hasjanus5[id] && !g_janusmode[id] && g_ready[id]){
		set_weapon_animation(id, 14);
	}
	else if(g_hasjanus5[id] && g_janusmode[id]){
		set_weapon_animation(id, 7);
	}
	set_pdata_float(id, 46, 41/30.0, 4);
	set_pdata_float(id, 47, 41/30.0, 4);
	set_pdata_float(id, 48, 41/30.0, 4);
	set_pdata_float(id, 83, 41/30.0, 5);
	return HAM_SUPERCEDE
}

public fw_WeaponIdle(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasjanus5[id]){
		return HAM_SUPERCEDE
	}
	else{
		return HAM_IGNORED
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M4A1 && g_hasjanus5[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(!g_janusmode[id] && !g_ready[id] && g_sattack[id] < get_pcvar_num(cvar_janus5shots)){
				emit_sound(id, CHAN_VOICE, "common/wpn_denyselect.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		}
	}
}

public sec_attack(id){
	g_sattack[id] += 1
	if(g_sattack[id] >= get_pcvar_num(cvar_janus5shots) && g_hasjanus5[id]){
		g_ready[id] = true
		client_cmd(id, "spk weapons/change1_ready.wav");
		set_weapon_animation(id, 12);
		set_sec_ammo(id, 1);
	}
}

public sectime(id){
	g_sectime[id] += 1
	if(g_sectime[id] >= 10 && g_hasjanus5[id] && g_janusmode[id]){
		g_janusmode[id] = false
		g_ready[id] = false
		g_sattack[id] = 0
		set_sec_ammo(id, 0);
		set_weapon_animation(id, 11);
		set_pdata_float(id, 46, 51/30.0, 4);
		set_pdata_float(id, 47, 51/30.0, 4);
		set_pdata_float(id, 48, 51/30.0, 4);
		set_pdata_float(id, 83, 51/30.0, 5);
		remove_task(id);
	}
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_m4a1.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m4a1", entity);
	
	if(g_hasjanus5[owner] && pev_valid(wpn))
	{
		if(g_janusmode[owner]){
			remove_task(owner);
		}
		g_hasjanus5[owner] = false
		g_janusmode[owner] = false
		g_ready[owner] = false
		UTIL_WeaponList(owner, false);
		g_sattack[owner] = 0
		set_sec_ammo(owner, 0);
	}
	set_pev(wpn, pev_impulse, 55555);
	engfunc(EngFunc_SetModel, entity, g_wmodel);
		
	return FMRES_SUPERCEDE;
}

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 55555)
	{
		g_hasjanus5[id] = true;
		g_janusmode[id] = false
		g_ready[id] = false
		g_sattack[id] = 0
		set_sec_ammo(id, 0);
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_Spawn(id){
	if(g_hasjanus5[id]){
		g_janusmode[id] = false
		g_ready[id] = false
		g_sattack[id] = 0
		set_sec_ammo(id, 0);
		set_weapon_animation(id, 2);
	}
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_sec_ammo(id, const SecAmmo){
	message_begin(MSG_ONE, msgid_ammox, _, id);
	write_byte(1);
	write_byte(SecAmmo);
	message_end();
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_janusmk5" : "weapon_m4a1");
	write_byte(4);
	write_byte(90);
	write_byte(1);
	write_byte(1);
	write_byte(0);
	write_byte(6);
	write_byte(22);
	write_byte(0);
	message_end();
}

stock UTIL_MakeBloodAndBulletHoles(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	if(target > 0 && target <= get_maxplayers() && zp_get_user_zombie(target)){
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
