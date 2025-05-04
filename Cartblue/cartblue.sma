#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <StripWeapons>

new g_hascartblue[33];
new g_cartblueammo[33];
new g_cartblueammo2[33];
new g_weaponmode[33];
new blood_spr[2];
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_cartblue.mdl"
new const g_pmodel[] = "models/p_cartblue.mdl"
new const g_wmodel[] = "models/w_cartblue.mdl"

public plugin_init() {
	register_plugin("Cartblue", "1.0", "bako35");
	register_clcmd("gun", "give_cartblue");
	register_clcmd("add_weapon", "add_weapon");
	register_clcmd("bakoweapon_cartbluec", "HookWeapon");
	register_clcmd("bakoweapon_cartblues", "HookWeapon2");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_SetModel, "fw_SetModel2");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_m4a1", "fw_SecondaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_PrimaryAttack2");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550", "fw_PrimaryAttack_Post2", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_sg550", "fw_ReloadWeapon2", 1);
	//RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "fw_Deploy");
	//RegisterHam(Ham_Item_Deploy, "weapon_sg550", "fw_Deploy2");
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_sg550", "fw_DeployPost2", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m4a1", "fw_WeaponIdle", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_sg550", "fw_WeaponIdle2", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_sg550", "fw_AddToPlayer2", 1);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/cart_first_clipin.wav");
	precache_sound("weapons/cart_first_clipout.wav");
	precache_sound("weapons/cart_first_draw.wav");
	precache_sound("weapons/cart_foley1.wav");
	precache_sound("weapons/cart_foley2.wav");
	precache_sound("weapons/cart_foley3.wav");
	precache_sound("weapons/cart_foley4.wav");
	precache_sound("weapons/cart_jump.wav");
	precache_sound("weapons/cart_lclipin.wav");
	precache_sound("weapons/cart_second_clipout.wav");
	precache_sound("weapons/cart_second_draw.wav");
	precache_sound("weapons/cart_second_hit.wav");
	precache_sound("weapons/cart_spindown.wav");
	precache_sound("weapons/cart_turn.wav");
	precache_sound("weapons/cart_yahoo.wav");
	precache_sound("weapons/cartblue_h.wav");
	precache_sound("weapons/cartblue_l.wav");
	precache_generic("sprites/cartblue/640hud49.spr");
	precache_generic("sprites/bakoweapon_cartbluec.txt");
	precache_generic("sprites/bakoweapon_cartblues.txt");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m4a1");
	return PLUGIN_HANDLED
}

public HookWeapon2(const client){
	engclient_cmd(client, "weapon_sg550");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hascartblue[id] = false
	g_weaponmode[id] = 0
	UTIL_WeaponList(id, false);
	UTIL_WeaponList2(id, false);
}

public client_disconnect(id){
	g_hascartblue[id] = false
	g_weaponmode[id] = 0
	UTIL_WeaponList(id, false);
	UTIL_WeaponList2(id, false);
}

public death_player(){
	g_hascartblue[read_data(2)] = false
	g_weaponmode[read_data(2)] = 0
	UTIL_WeaponList(read_data(2), false);
	UTIL_WeaponList2(read_data(2), false);
}

public give_cartblue(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_M4A1) || user_has_weapon(id, CSW_SG550)){
			drop_weapon(id);
		}
		g_hascartblue[id] = true
		g_weaponmode[id] = 1
		UTIL_WeaponList(id, true);
		UTIL_WeaponList2(id, true);
		give_item(id, "weapon_m4a1");
		give_item(id, "weapon_sg550");
		cs_set_user_bpammo(id, CSW_M4A1, 200);
		cs_set_user_bpammo(id, CSW_SG550, 200);
		replace_models(id);
	}
}

public test(id){
	if(is_user_alive(id)){
		StripWeapons(id, Primary);
	}
}

public replace_models(id){
	new cartblue = read_data(2);
	if(g_hascartblue[id] && cartblue == CSW_M4A1 || cartblue == CSW_SG550){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_M4A1) || (1<<CSW_SG550) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && g_hascartblue[id] && get_user_weapon(id) == CSW_M4A1 || get_user_weapon(id) == CSW_SG550)
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hascartblue[id]){
		g_cartblueammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hascartblue[id]){
		g_cartblueammo2[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hascartblue[id] && g_cartblueammo[id] && g_weaponmode[id] == 1){
			emit_sound(id, CHAN_WEAPON, "weapons/cartblue_l.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_weapon_animation(id, random_num(3, 4));
			UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_PrimaryAttack_Post2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hascartblue[id] && g_cartblueammo2[id] && g_weaponmode[id] == 2){
			emit_sound(id, CHAN_WEAPON, "weapons/cartblue_h.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_weapon_animation(id, random_num(9, 10));
			UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hascartblue[id] && g_weaponmode[id] == 1){
		set_weapon_animation(id, 1);
		set_pdata_float(id, 46, 104/30.0, 4);
		set_pdata_float(id, 47, 104/30.0, 4);
		set_pdata_float(id, 48, 104/30.0, 4);
		set_pdata_float(id, 83, 104/30.0, 5);
	}
}

public fw_ReloadWeapon2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hascartblue[id] && g_weaponmode[id] == 2){
		set_weapon_animation(id, 7);
		set_pdata_float(id, 46, 104/30.0, 4);
		set_pdata_float(id, 47, 104/30.0, 4);
		set_pdata_float(id, 48, 104/30.0, 4);
		set_pdata_float(id, 83, 104/30.0, 5);
	}
}

public fw_SecondaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hascartblue[id]){
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

/*public fw_Deploy(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hascartblue[id] && get_user_weapon(id) != CSW_M4A1 && get_user_weapon(id) != CSW_SG550 && g_weaponmode[id] == 2){
		client_cmd(id, "slot1");
		client_cmd(id, "slot1");
		client_cmd(id, "+attack");
		return HAM_IGNORED
	}
}

public fw_Deploy2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hascartblue[id] && get_user_weapon(id) != CSW_M4A1 && get_user_weapon(id) != CSW_SG550 && g_weaponmode[id] == 1){
		client_cmd(id, "slot1");
		client_cmd(id, "+attack");
		return HAM_IGNORED
	}
}*/

public fw_DeployPost(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hascartblue[id]){
		if(get_user_weapon(id) != CSW_SG550){
			set_weapon_animation(id, 2);
			set_pdata_float(id, 83, 30/30.0, 5);
		}
		else if(get_user_weapon(id) == CSW_SG550){
			new new_weapon_entity = find_ent_by_owner(-1, "weapon_sg550", id)
			set_weapon_animation(id, 11);
			set_pdata_float(id, 83, 145/30.0, 5);
			g_weaponmode[id] = 1
			if(new_weapon_entity){
				cs_set_weapon_ammo(weapon_entity, get_pdata_int(new_weapon_entity, 51, 4))
			}
		}
	}
}

public fw_DeployPost2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hascartblue[id]){
		if(get_user_weapon(id) != CSW_M4A1){
			set_weapon_animation(id, 8);
			set_pdata_float(id, 83, 37/30.0, 5);
		}
		else if(get_user_weapon(id) == CSW_M4A1){
			new new_weapon_entity = find_ent_by_owner(-1, "weapon_m4a1", id)
			set_weapon_animation(id, 5);
			set_pdata_float(id, 83, 145/30.0, 5);
			g_weaponmode[id] = 2
			if(new_weapon_entity){
				cs_set_weapon_ammo(weapon_entity, get_pdata_int(new_weapon_entity, 51, 4))
			}
		}
	}
}

public fw_WeaponIdle(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(!is_user_alive(id) || !g_hascartblue[id] || get_user_weapon(id) != CSW_M4A1){
		return HAM_IGNORED
	}
	if(g_hascartblue[id] && g_weaponmode[id] == 1 && get_user_weapon(id) == CSW_M4A1 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 0);
		set_pdata_float(weapon_entity, 48, 161/30.0, 4);
		return HAM_SUPERCEDE
	}
}

public fw_WeaponIdle2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(!is_user_alive(id) || !g_hascartblue[id] || get_user_weapon(id) != CSW_SG550){
		return HAM_IGNORED
	}
	if(g_hascartblue[id] && g_weaponmode[id] == 2 && get_user_weapon(id) == CSW_SG550 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 6);
		set_pdata_float(weapon_entity, 48, 161/30.0, 4);
		return HAM_SUPERCEDE
	}
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_m4a1.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m4a1", entity);
	
	if(g_hascartblue[owner] && pev_valid(wpn)){
		new data[1]
		data[0] = owner
		g_hascartblue[owner] = false;
		g_weaponmode[owner] = 0;
		UTIL_WeaponList(owner, false);
		UTIL_WeaponList2(owner, false);
		set_pev(wpn, pev_impulse, 7777777);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		StripWeapons(owner, Primary);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_SetModel2(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_sg550.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_sg550", entity);
	
	if(g_hascartblue[owner] && pev_valid(wpn)){
		new data[1]
		data[0] = owner
		g_hascartblue[owner] = false;
		g_weaponmode[owner] = 0;
		UTIL_WeaponList(owner, false);
		UTIL_WeaponList2(owner, false);
		set_pev(wpn, pev_impulse, 7777778);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		StripWeapons(owner, Primary);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 7777777){
		g_hascartblue[id] = true;
		g_weaponmode[id] = 1
		UTIL_WeaponList(id, true);
		client_cmd(id, "add_weapon");
		set_pev(weapon_entity, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public add_weapon(id){
	new wpn = find_ent_by_owner(-1, "weapon_sg550", id)
	if(pev_valid(wpn)){
		UTIL_WeaponList(id, true);
		give_item(id, "weapon_m4a1");
	}
	else{
		UTIL_WeaponList2(id, true);
		give_item(id, "weapon_sg550");
	}
}

public fw_AddToPlayer2(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 7777778)
	{
		g_hascartblue[id] = true;
		g_weaponmode[id] = 1
		UTIL_WeaponList2(id, true);
		client_cmd(id, "add_weapon");
		set_pev(weapon_entity, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
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

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_cartbluec" : "weapon_m4a1");
	write_byte(4);
	write_byte(90);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(6);
	write_byte(22);
	write_byte(0);
	message_end();
}

stock UTIL_WeaponList2(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_cartblues" : "weapon_sg550");
	write_byte(4);
	write_byte(90);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(16);
	write_byte(13);
	write_byte(0);
	message_end();
}
