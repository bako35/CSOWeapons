#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombieplague>

new g_hasm2hb[33];
new g_m2hbammo[33];
new seccammo[33];
new msgid_ammox;
new task[33];
new blood_spr[2];
new g_exp;
new g_secdeath;
new trail;
new m2hb;

new const wep_m249 = ((1<<CSW_M249));
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_mgsm_full_v2.mdl";
new const g_pmodel[] = "models/p_mgsm_pack.mdl";
new const g_wmodel[] = "models/w_mgsm.mdl";

public plugin_init() {
	register_plugin("M2HB Devastator", "1.0", "bako35");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "fw_DeployPost", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m249", "fw_WeaponIdle");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Spawn, "player", "fw_Spawn");
	register_clcmd("bakoweapons_mgsm", "HookWeapon");
	msgid_ammox = get_user_msgid("AmmoX");
	g_secdeath = get_user_msgid("DeathMsg");
	m2hb = zp_register_extra_item("M2HB Devastator", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/mgsm_clipin1.wav");
	precache_sound("weapons/mgsm_clipin2.wav");
	precache_sound("weapons/mgsm_clipout1.wav");
	precache_sound("weapons/mgsm_clipout2.wav");
	precache_sound("weapons/mgsm_draw.wav");
	precache_sound("weapons/mgsm_exp.wav");
	precache_sound("weapons/mgsm_gauge.wav");
	precache_sound("weapons/mgsm_launcher_on.wav");
	precache_sound("weapons/mgsm_launcher_shoot.wav");
	precache_sound("weapons/mgsm-1.wav");
	precache_sound("weapons/mgsm-2.wav");
	precache_generic("sprites/640hud40.spr");
	precache_generic("sprites/640hud41.spr");
	precache_generic("sprites/640hud209.spr");
	precache_generic("sprites/bakoweapons_mgsm.txt");
	g_exp = precache_model("sprites/fexplo.spr");
	trail = precache_model("sprites/laserbeam.spr");
}

public client_connect(id){
	g_hasm2hb[id] = false
	task[id] = false
	seccammo[id] = 0
}

public client_disconnect(id){
	g_hasm2hb[id] = false
	task[id] = false
	seccammo[id] = 0
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m249");
}

public zp_extra_item_selected(id, itemid){
	if(itemid == m2hb){
		give_m2hb(id)
	}
}

public give_m2hb(id){
	if(is_user_alive(id) && !g_hasm2hb[id]){
		if(user_has_weapon(id, CSW_M249)){
			drop_weapon(id);
		}
		g_hasm2hb[id] = true
		give_item(id, "weapon_m249");
		UTIL_WeaponList(id, true);
		cs_set_user_bpammo(id, CSW_M249, 200);
		replace_models(id);
		set_task(0.1, "sec_ammo", id, _, _, "b")
		task[id] = true
		if(seccammo[id] >= 100){
			set_anim_weapon(id, 3)
		}
		else{
			set_anim_weapon(id, 2)
		}
	}
}

public death_player(id){
	g_hasm2hb[read_data(2)] = false
	seccammo[read_data(2)] = 0
	UTIL_WeaponList(read_data(2), false);
	set_sec_ammo(read_data(2), seccammo[id]);
	if(task[read_data(2)]){
		remove_task(read_data(2));
		task[read_data(2)] = false
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++){
		if(wep_m249 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

public replace_models(id){
	new m2hb = read_data(2);
	if(g_hasm2hb[id] && m2hb == CSW_M249){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public sec_ammo(id){
	seccammo[id] += 1
	set_sec_ammo(id, seccammo[id]+1);
	if(seccammo[id] >= 100 && g_hasm2hb[id]){
		remove_task(id);
		task[id] = false
		seccammo[id] = 100
		set_sec_ammo(id, seccammo[id]);
		if(user_has_weapon(id, CSW_M249)){
			set_anim_weapon(id, 8);
			emit_sound(id, CHAN_VOICE, "weapons/mgsm_gauge.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasm2hb[id]){
		g_m2hbammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M249 && g_hasm2hb[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasm2hb[id] && g_m2hbammo[id]){
		emit_sound(id, CHAN_WEAPON, "weapons/mgsm-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		if(seccammo[id] >= 100){
			set_anim_weapon(id, 7);
		}
		else{
			set_anim_weapon(id, 6);
		}
		UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasm2hb[id] && seccammo[id] >= 100){
		set_anim_weapon(id, 5);
	}
	else if(g_hasm2hb[id] && seccammo[id] <= 100){
		set_anim_weapon(id, 4);
	}
		set_pdata_float(id, 46, 91/30.0, 4);
		set_pdata_float(id, 47, 91/30.0, 4);
		set_pdata_float(id, 48, 91/30.0, 4);
		set_pdata_float(id, 83, 91/30.0, 5);
}

public fw_CmdStart(id, uc_handle, seed){
	if((is_user_alive(id) && get_user_weapon(id) == CSW_M249) && g_hasm2hb[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(seccammo[id] >= 100){
				secshoot(id);
				set_anim_weapon(id, 9);
				emit_sound(id, CHAN_WEAPON, "weapons/mgsm-2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				seccammo[id] = 0
				set_sec_ammo(id, seccammo[id]);
				set_task(0.1, "sec_ammo", id, _, _, "b")
				task[id] = true
			}
		}
	}
}

public secshoot(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "m2hb_devastator_rocket");
	entity_set_model(rocket, "models/grenade.mdl");
	entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	entity_set_int(rocket, EV_INT_movetype, MOVETYPE_FLY);
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
		if(equal(classname, "m2hb_devastator_rocket")){
			static Float:attacker
			attacker = pev(ptr, pev_owner)
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			emit_sound(ptr, CHAN_ITEM, "weapons/mgsm_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
			if(distance <= 300){
				new hp
				hp = get_user_health(i)
				new Float:dam
				dam = 2000-2000/300*float(distance)
				new origin[3]
				get_user_origin(i, origin)
				if(get_user_team(id) != get_user_team(i)){
					if(hp > dam){
						damage(i, floatround(dam), origin, DMG_BLAST);
					}
					else{
						wepkill(id, i);
					}
				}
			}
		}
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasm2hb[id] && seccammo[id] >= 100){
		set_anim_weapon(id, 3);
	}
	else if(g_hasm2hb[id] && seccammo[id] < 100){
		set_anim_weapon(id, 2)
	}
}

public fw_WeaponIdle(weapon_entity){
	return HAM_SUPERCEDE
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_m249.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m249", entity);
	
	if(g_hasm2hb[owner] && pev_valid(wpn))
	{
		g_hasm2hb[owner] = false;
		if(task[owner]){
			remove_task(owner)
			task[owner] = false
			seccammo[owner] = 0
			set_sec_ammo(owner, seccammo[owner])
		}
		set_pev(wpn, pev_impulse, 43557);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43557)
	{
		g_hasm2hb[id] = true;
		task[id] = true
		set_task(0.1, "sec_ammo", id, _, _, "b")
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_Spawn(id){
	if(g_hasm2hb[id]){
		if(!task[id]){
		set_task(0.1, "sec_ammo", id, _, _, "b")
		task[id] = true
		}
	seccammo[id] = 0
	set_sec_ammo(id, seccammo[id])
	set_anim_weapon(id, 2)
	}
}

stock wepkill(attacker, victim){
	set_msg_block(g_secdeath, BLOCK_SET)
	ExecuteHamB(Ham_Killed, victim, attacker, 2)
	set_msg_block(g_secdeath, BLOCK_NOT)
	SendDeathMsg(attacker, victim);
	
	if(get_user_team(attacker) != get_user_team(victim)){
		set_user_frags(attacker, get_user_frags(attacker) +1);
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) +1);
	}
	if(get_user_team(attacker) == get_user_team(victim)){
		set_user_frags(attacker, get_user_frags(attacker) -1);
	}
	
	return PLUGIN_CONTINUE
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapons_mgsm" : "weapon_m249");
	write_byte(3);
	write_byte(200);
	write_byte(1);
	write_byte(100);
	write_byte(0);
	write_byte(4);
	write_byte(20);
	write_byte(0);
	message_end();
}

stock set_sec_ammo(id, const SecAmmo){
	message_begin(MSG_ONE, msgid_ammox, _, id);
	write_byte(1);
	write_byte(SecAmmo);
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

stock set_anim_weapon(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock damage(victim,dam,origin[3],bit){
	message_begin(MSG_ONE, get_user_msgid("Damage"), {0,0,0}, victim)
	write_byte(21)
	write_byte(20)
	write_long(bit)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	message_end()
	
	fakedamage(victim, "", dam, DMG_BLAST)
	set_user_health(victim, get_user_health(victim) - dam)
}

stock SendDeathMsg(attacker, victim){ // Sends death message
	message_begin(MSG_BROADCAST, g_secdeath)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("m249") // killer's weapon
	message_end()
}
