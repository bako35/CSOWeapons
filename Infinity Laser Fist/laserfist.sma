#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

new g_haslaserfist[33];
new g_laserfistammo[33];
new g_weaponmode[33];
new g_secshoot[33];
new g_exp;
new g_trail;
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_laserfist.mdl"
new const g_vmodel2[] = "models/v_laserfist2.mdl"
new const g_pmodel[] = "models/p_laserfist.mdl"
new const g_wmodel[] = "models/w_laserfist.mdl"

public plugin_init() {
	register_plugin("Infinity Laser Fist", "1.0", "bako35");
	register_clcmd("gun", "give_laserfist");
	register_clcmd("bakoweapon_laserfist", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_tmp", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tmp", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tmp", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_tmp", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_tmp", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_tmp", "fw_DeployPost", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_tmp", "fw_WeaponIdle");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_vmodel2);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/laserfist_b1.wav");
	precache_sound("weapons/laserfist_clipin1.wav");
	precache_sound("weapons/laserfist_clipin2.wav");
	precache_sound("weapons/laserfist_clipout.wav");
	precache_sound("weapons/laserfist_draw1.wav");
	precache_sound("weapons/laserfist_idle.wav");
	precache_sound("weapons/laserfist_shoota_empty_end.wav");
	precache_sound("weapons/laserfist_shoota_empty_loop.wav");
	precache_sound("weapons/laserfist_shoota-1.wav");
	precache_sound("weapons/laserfist_shootb_exp.wav");
	precache_sound("weapons/laserfist_shootb_loop.wav");
	precache_sound("weapons/laserfist_shootb_ready.wav");
	precache_sound("weapons/laserfist_shootb_shoot.wav");
	precache_sound("weapons/laserfist_shootb-1.wav");
	precache_generic("sprites/bakoweapon_laserfist.txt");
	precache_generic("sprites/laserfist/640hud36.spr");
	precache_generic("sprites/laserfist/640hud188.spr");
	g_exp = precache_model("sprites/laserfist/ef_laserfist_laser_explosion.spr");
	g_trail = precache_model("sprites/laserfist/ef_laserfist_laserbeam.spr");
	
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_tmp");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_haslaserfist[id] = false
	g_secshoot[id] = 0
	g_weaponmode[id] = 1
}

public client_disconnect(id){
	g_haslaserfist[id] = false
	g_secshoot[id] = 0
	g_weaponmode[id] = 1
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_haslaserfist[read_data(2)] = false
	g_secshoot[read_data(2)] = 0
	g_weaponmode[read_data(2)] = 1
	UTIL_WeaponList(read_data(2), false);
}

public give_laserfist(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_TMP)){
			drop_weapon(id);
		}
		g_haslaserfist[id] = true
		g_secshoot[id] = 0
		g_weaponmode[id] = 1
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_tmp")
		cs_set_weapon_ammo(wpnid, 100);
		cs_set_user_bpammo(id, CSW_TMP, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new laserfist = read_data(2);
	if(g_haslaserfist[id] && laserfist == CSW_TMP){
		if(g_secshoot[id] != 20){
			set_pev(id, pev_viewmodel2, g_vmodel);
		}
		else if(g_secshoot[id] == 20){
			set_pev(id, pev_viewmodel2, g_vmodel2);
		}
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_TMP) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_haslaserfist[id]){
		static iclipex = 100
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_TMP);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_TMP, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_TMP && g_haslaserfist[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_haslaserfist[id] && g_weaponmode[id] == 1){
		g_laserfistammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	else if(g_weaponmode[id] == 2){
		g_laserfistammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_haslaserfist[id] && g_laserfistammo[id] && g_weaponmode[id] == 1){
		g_secshoot[id] += 1
		if(g_secshoot[id] >= 20){
			set_pev(id, pev_viewmodel2, g_vmodel2);
			g_secshoot[id] = 20
		}
		emit_sound(id, CHAN_WEAPON, "weapons/laserfist_shoota-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 3);
		UTIL_MakeBloodAndBulletHoles(id);
	}
	else if(g_weaponmode[id] == 2 && g_secshoot[id] == 20){
		set_pev(id, pev_viewmodel2, g_vmodel);
		g_weaponmode[id] = 1
		g_secshoot[id] = 0
		emit_sound(id, CHAN_WEAPON, "weapons/laserfist_shootb-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 7);
		set_pdata_float(id, 83, 50/30.0, 5);
		UTIL_Explode(id);
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
		
	new res;
	engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res);
	get_tr2(res, TR_vecEndPos, fRes);
		
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fStart[0])
	engfunc(EngFunc_WriteCoord, fStart[1])
	engfunc(EngFunc_WriteCoord, fStart[2])
	write_short(g_exp)
	write_byte(8)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,fPlayer[0]);
	engfunc(EngFunc_WriteCoord,fPlayer[1]);
	engfunc(EngFunc_WriteCoord,fPlayer[2]);
	engfunc(EngFunc_WriteCoord,fStart[0]); //Random
	engfunc(EngFunc_WriteCoord,fStart[1]); //Random
	engfunc(EngFunc_WriteCoord,fStart[2]); //Random
	write_short(g_trail);
	write_byte(0);
	write_byte(100);
	write_byte(10);	//Life
	write_byte(100);//Width
	write_byte(0);	//wave
	write_byte(255); // r
	write_byte(255); // g
	write_byte(255); // b
	write_byte(255); // alpha
	write_byte(255); // speed (?)
	message_end();
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, 30.0)) != 0){
		if(!is_user_alive(victim) || get_user_team(id) == get_user_team(victim)){
			continue
		}
		ExecuteHamB(Ham_TakeDamage, victim, id, id, 100.0, DMG_ENERGYBEAM|DMG_NEVERGIB);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_haslaserfist[id] && g_weaponmode[id] == 1){
		set_weapon_animation(id, 8);
		set_pdata_float(id, 46, 81/30.0, 4);
		set_pdata_float(id, 47, 81/30.0, 4);
		set_pdata_float(id, 48, 81/30.0, 4);
		set_pdata_float(id, 83, 81/30.0, 5);
	}
}

public fw_CmdStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_haslaserfist[id] && get_user_weapon(id) == CSW_TMP){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 3 && g_weaponmode[id] == 1){
			set_weapon_animation(id, 4);
		}
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1 && g_secshoot[id] == 20){
				set_weapon_animation(id, 5);
				set_pdata_float(id, 83, 39/30.0, 5);
				g_weaponmode[id] = 2
			}
			else if(g_secshoot[id] != 20 || g_weaponmode[id] == 2){
				emit_sound(id, CHAN_VOICE, "common/wpn_denyselect.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		}
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

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 6789)
	{
		g_haslaserfist[id] = true;
		g_weaponmode[id] = 1
		g_secshoot[id] = pev(weapon_entity, pev_iuser4);
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_tmp.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_tmp", entity);
	
	if(g_haslaserfist[owner] && pev_valid(wpn)){
		g_haslaserfist[owner] = false;
		g_weaponmode[owner] = 1
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 6789);
		set_pev(wpn, pev_iuser4, g_secshoot[owner]);
		g_secshoot[owner] = 0
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_DeployPost(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_haslaserfist[id]){
		set_weapon_animation(id, 9);
		set_pdata_float(id, 46, 51/30.0, 4);
		set_pdata_float(id, 47, 51/30.0, 4);
		set_pdata_float(id, 48, 51/30.0, 4);
		set_pdata_float(id, 83, 51/30.0, 5);
	}
}

public fw_WeaponIdle(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!is_user_alive(id) || !g_haslaserfist[id] || get_user_weapon(id) != CSW_TMP || g_weaponmode[id] != 2){
		return HAM_IGNORED
	}
	else if(g_haslaserfist[id] && g_weaponmode[id] == 2 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 6);
		set_pdata_float(weapon_entity, 48, 31/30.0, 4);
		return HAM_SUPERCEDE
	}
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_laserfist" : "weapon_tmp");
	write_byte(10)
	write_byte(120)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(11)
	write_byte(23)
	write_byte(0)
	message_end();
}
