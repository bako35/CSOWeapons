#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hassvd[33];
new g_svdammo[33];
new blood_spr[2];
new ammox[33];
new g_weaponmode[33];
new msgid_ammox;
new trail;
new g_exp;
new g_secdeath;
new svd;
new svdammo;
new cvar_ammo;
new cvar_alt_ammo;
new cvar_alt_damage;
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_svdex.mdl"
new const g_pmodel[] = "models/p_svdex.mdl"
new const g_wmodel[] = "models/w_svdex.mdl"
new const g_shootsound[] = "weapons/svdex-1.wav"
new const g_launchersound[] = "weapons/svdex-launcher.wav"

public plugin_init() {
	register_plugin("SVD Custom", "1.0", "bako35");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_ak47", "fw_WeaponIdle");
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	msgid_ammox = get_user_msgid("AmmoX");
	g_secdeath = get_user_msgid("DeathMsg");
	svd = zp_register_extra_item("SVD Custom", 0, ZP_TEAM_HUMAN);
	svdammo = zp_register_extra_item("SVD Custom Ammo", 0, ZP_TEAM_HUMAN);
	cvar_ammo = register_cvar("svdex_ammo", "20");
	cvar_alt_ammo = register_cvar("svdex_alt_ammo", "10");
	cvar_alt_damage = register_cvar("svdex_alt_damage", "50.0");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound(g_launchersound);
	precache_sound("weapons/svdex_clipin.wav");
	precache_sound("weapons/svdex_clipon.wav");
	precache_sound("weapons/svdex_clipout.wav");
	precache_sound("weapons/svdex_draw.wav");
	precache_sound("weapons/svdex_exp.wav");
	precache_sound("weapons/svdex_foley1.wav");
	precache_sound("weapons/svdex_foley2.wav");
	precache_sound("weapons/svdex_foley3.wav");
	precache_sound("weapons/svdex_foley4.wav");
	precache_generic("sprites/cso/640hud7.spr");
	precache_generic("sprites/640hud36.spr");
	precache_generic("sprites/640hud41.spr");
	precache_generic("sprites/bakoweapon_svdex.txt");
	precache_generic("sprites/blue_scope.spr");
	g_exp = precache_model("sprites/fexplo.spr");
	trail = precache_model("sprites/laserbeam.spr");
}

public client_connect(id){
	g_hassvd[id] = false
	g_weaponmode[id] = 1
	ammox[id] = 0
}

public client_disconnect(id){
	g_hassvd[id] = false
	g_weaponmode[id] = 1
	ammox[id] = 0
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hassvd[read_data(2)] = false
	g_weaponmode[read_data(2)] = 1
	ammox[read_data(2)] = 0
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hassvd[id] = false
	g_weaponmode[id] = 1
	ammox[id] = 0
	UTIL_WeaponList(id, false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == svd){
		give_svd(id);
	}
	else if(itemid == svdammo){
		if(is_user_alive(id) && g_hassvd[id] && ammox[id] < 10){
			ammox[id] = 10
			set_sec_ammo(id, ammox[id])
			client_cmd(id, "spk items/9mmclip1.wav");
		}
		else{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 0);
		}
	}
}

public give_svd(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_AK47)){
			drop_weapon(id);
		}
		g_hassvd[id] = true
		UTIL_WeaponList(id, true);
		g_weaponmode[id] = 1
		ammox[id] = get_pcvar_num(cvar_alt_ammo)
		new wpnid
		wpnid = give_item(id, "weapon_ak47");
		cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_ammo));
		cs_set_user_bpammo(id, CSW_AK47, 200);
		set_sec_ammo(id, ammox[id]);
		replace_models(id);
	}
}

public replace_models(id){
	new svd = read_data(2);
	if(g_hassvd[id] && svd == CSW_AK47){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_AK47) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hassvd[id] && g_weaponmode[id] == 1){
		g_svdammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	else if(g_weaponmode[id] == 2){
		g_svdammo[id] = cs_get_weapon_ammo(weapon_entity);
		return HAM_SUPERCEDE
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hassvd[id] && g_svdammo[id]){
		if(g_weaponmode[id] == 1){
			emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			UTIL_MakeBloodAndBulletHoles(id);
			set_weapon_animation(id, 1);
			set_pdata_float(id, 83, 0.4, 5);
		}
		else if(g_weaponmode[id] == 2){
			if(ammox[id] > 1){
				emit_sound(id, CHAN_WEAPON, g_launchersound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_weapon_animation(id, 5);
				launchershoot(id);
				set_pdata_float(id, 83, 91/30.0, 5);
				ammox[id] -= 1
				set_sec_ammo(id, ammox[id]);
			}
			else if(ammox[id] == 1){
				emit_sound(id, CHAN_WEAPON, g_launchersound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_weapon_animation(id, 6);
				launchershoot(id);
				set_pdata_float(id, 83, 36/30.0, 5);
				ammox[id] = 0
				set_sec_ammo(id, ammox[id]);
			}
			else if(ammox[id] == 0){
				ExecuteHamB(Ham_Weapon_PlayEmptySound, weapon_entity);
				set_pdata_float(id, 83, 0.2, 5);
				ammox[id] = 0
				set_sec_ammo(id, ammox[id]);
			}
		}
	}
}

public launchershoot(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "svd_grenade");
	entity_set_model(rocket, "models/grenade.mdl");
	entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	entity_set_int(rocket, EV_INT_movetype, MOVETYPE_BOUNCE);
	entity_set_int(rocket, EV_INT_solid, SOLID_BBOX);
	
	new Float:vsrc[3]
	entity_get_vector(id, EV_VEC_origin, vsrc);
	
	new Float:aim[3]
	new Float:origin[3]
	VelocityByAim(id, 64, aim);
	entity_get_vector(id, EV_VEC_origin, origin);
	
	vsrc[0] += aim[0]
	vsrc[1] += aim[1]
	entity_set_origin(rocket, vsrc);
	
	new Float:velocity[3]
	new Float:angles[3]
	VelocityByAim(id, 1500, velocity);
	entity_set_vector(rocket, EV_VEC_velocity, velocity);
	vector_to_angle(velocity, angles);
	entity_set_vector(rocket, EV_VEC_angles, angles);
	entity_set_edict(rocket, EV_ENT_owner, id);
	entity_set_float(rocket, EV_FL_takedamage, 1.0);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(rocket)
	write_short(trail)
	write_byte(10)
	write_byte(10)
	write_byte(225)
	write_byte(225)
	write_byte(255)
	write_byte(255)
	message_end()
}

public pfn_touch(ptr, ptd){
	if(is_valid_ent(ptr)){
		new classname[32]
		entity_get_string(ptr, EV_SZ_classname, classname, 31);
		if(equal(classname, "svd_grenade")){
			static Float:attacker
			attacker = pev(ptr, pev_owner)
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			emit_sound(ptr, CHAN_ITEM, "weapons/svdex_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			radius(ptr);
			remove_entity(ptr);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iorigin)
			write_byte(TE_EXPLOSION)
			write_coord(iorigin[0])
			write_coord(iorigin[1])
			write_coord(iorigin[2])
			write_short(g_exp)
			write_byte(30)
			write_byte(30)
			write_byte(4)
			message_end()
			
			if(is_valid_ent(ptd)){
				new classname2[32]
				entity_get_string(ptd, EV_SZ_classname, classname2, 31);
				if(equal(classname2, "func_breakable")){
					force_use(ptr, ptd);
				}
				remove_entity(ptr);
			}
		}
	}
	return PLUGIN_CONTINUE
}

public radius(entity){
	new id = entity_get_edict(entity, EV_ENT_owner)
	for(new i = 1; i < 33; i++){
		if(is_user_alive(i)){
			new distance
			distance = floatround(entity_range(entity, i))
			if(distance <= 100){
				if(get_user_team(id) != get_user_team(i)){
					set_msg_block(g_secdeath, BLOCK_SET);
					ExecuteHamB(Ham_TakeDamage, i, 0, id, get_pcvar_num(cvar_alt_damage), DMG_BLAST);
					set_msg_block(g_secdeath, BLOCK_NOT);
					if(get_user_health(i) <= 0){
						SendDeathMsg(id, i, 0, "ak47");
					}
				}
			}
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hassvd[id]){
		static iclipex
		iclipex = get_pcvar_num(cvar_ammo)
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_AK47);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_AK47, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_AK47 && g_hassvd[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if((is_user_alive(id) && get_user_weapon(id) == CSW_AK47) && g_hassvd[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1){
				set_weapon_animation(id, 8);
				set_pdata_float(id, 83, 46/30.0, 5);
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
				g_weaponmode[id] = 2
			}
			else if(g_weaponmode[id] == 2){
				set_weapon_animation(id, 9);
				set_pdata_float(id, 83, 46/30.0, 5);
				cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
				g_weaponmode[id] = 1
			}
		}
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hassvd[id]){
		set_weapon_animation(id, 2);
		set_pdata_float(id, 46, 115/30.0, 4);
		set_pdata_float(id, 47, 115/30.0, 4);
		set_pdata_float(id, 48, 115/30.0, 4);
		set_pdata_float(id, 83, 115/30.0, 5);
		g_weaponmode[id] = 1
	}
}

public fw_WeaponIdle(weapon_entity){
	return HAM_SUPERCEDE
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hassvd[id] && g_weaponmode[id] == 1){
		set_weapon_animation(id, 3);
		set_pdata_float(id, 46, 31/30.0, 4);
		set_pdata_float(id, 47, 31/30.0, 4);
		set_pdata_float(id, 48, 31/30.0, 4);
		set_pdata_float(id, 83, 31/30.0, 5);
	}
	else if(g_weaponmode[id] == 2){
		set_weapon_animation(id, 7);
		set_pdata_float(id, 46, 31/30.0, 4);
		set_pdata_float(id, 47, 31/30.0, 4);
		set_pdata_float(id, 48, 31/30.0, 4);
		set_pdata_float(id, 83, 31/30.0, 5);
		cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 12122)
	{
		g_hassvd[id] = true;
		g_weaponmode[id] = 1
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_ak47.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_ak47", entity);
	
	if(g_hassvd[owner] && pev_valid(wpn))
	{
		g_hassvd[owner] = false;
		g_weaponmode[owner] = 1
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 12122);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_AK47 && g_hassvd[attacker] && g_weaponmode[attacker] == 1)
	{
		SetHamParamFloat(4, damage + 71.0);
	}
}

stock set_sec_ammo(id, const SecAmmo){
	message_begin(MSG_ONE, msgid_ammox, _, id);
	write_byte(1);
	write_byte(SecAmmo);
	message_end();
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

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_svdex" : "weapon_ak47");
	write_byte(2);
	write_byte(90);
	write_byte(bEnabled ? 1 : -1);
	write_byte(bEnabled ? get_pcvar_num(cvar_alt_ammo) : -1);
	write_byte(0);
	write_byte(1);
	write_byte(28);
	write_byte(0);
	message_end();
}

stock SendDeathMsg(attacker, victim, headshot, const KillersWeapon[]){ // Sends death message
	static bool:kwpn[64]
	format(kwpn, 63, "%s", KillersWeapon);
	
	message_begin(MSG_BROADCAST, g_secdeath)
	write_byte(attacker) // attacker
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag
	write_string(kwpn) // killer's weapon
	message_end()
}
