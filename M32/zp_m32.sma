#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hasm32[33];
new g_m32ammo[33];
new g_reload[33];
new zoom[33];
new g_trail;
new g_exp;
new g_secdeath;
new m32gl;
new const g_vmodel[] = "models/v_m32.mdl"
new const g_pmodel[] = "models/p_m32.mdl"
new const g_wmodel[] = "models/w_m32.mdl"

public plugin_init() {
	register_plugin("Grenade Launcher M32", "1.0", "bako35");
	register_clcmd("bakoweapon_m32", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_PostFrame, "weapon_m3", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "fw_ReloadWeapon");
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "fw_ReloadWeapon_2");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fw_AddToPlayer", 1);
	g_secdeath = get_user_msgid("DeathMsg");
	m32gl = zp_register_extra_item("Grenade Launcher M32", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/m32_after_reload.wav");
	precache_sound("weapons/m32_explosion.wav");
	precache_sound("weapons/m32_insert.wav");
	precache_sound("weapons/m32_start_reload.wav");
	precache_sound("weapons/m32-1.wav");
	precache_generic("sprites/m32/640hud7.spr");
	precache_generic("sprites/m32/640hud75.spr");
	precache_generic("sprites/blue_scope.spr");
	precache_generic("sprites/bakoweapon_m32.txt");
	g_exp = precache_model("sprites/fexplo.spr");
	g_trail = precache_model("sprites/laserbeam.spr");
}	

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m3");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasm32[id] = false
	zoom[id] = false
}

public client_disconnect(id){
	g_hasm32[id] = false
	zoom[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_hasm32[read_data(2)] = false
	zoom[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hasm32[id] = false
	zoom[id] = false
	UTIL_WeaponList(id, false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == m32gl){
		give_m32(id);
	}
}

public give_m32(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_M3)){
			drop_weapon(id);
		}
		g_hasm32[id] = true
		zoom[id] = false
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_m3")
		cs_set_weapon_ammo(wpnid, 6);
		cs_set_user_bpammo(id, CSW_M3, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new m32 = read_data(2);
	if(g_hasm32[id] && m32 == CSW_M3){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_M3) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M3 && g_hasm32[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	g_m32ammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_hasm32[id]){
		return HAM_IGNORED
	}
	if(!g_m32ammo[id]){
		ExecuteHamB(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE
	}
	if(g_reload[id]){
		set_weapon_animation(id, 4);
		set_pdata_float(id, 83, 27/30.0);
		remove_task(1000);
		g_reload[id] = false
		return HAM_SUPERCEDE
	}
	set_pdata_float(id, 83, 0.5, 5);
	set_pdata_float(weapon_entity, 46, 1.0, 4);
	set_pdata_float(weapon_entity, 1.5, 4);
	set_weapon_animation(id, random_num(1, 2));
	emit_sound(id, CHAN_WEAPON, "weapons/m32-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pdata_int(weapon_entity, 51, g_m32ammo[id] - 1, 4);
	launchershoot(id);
	return HAM_SUPERCEDE
}

public launchershoot(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "m32_grenade");
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
	write_short(g_trail)
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
		if(equal(classname, "m32_grenade")){
			static Float:attacker
			attacker = pev(ptr, pev_owner)
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			emit_sound(ptr, CHAN_VOICE, "weapons/m32_explosion.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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
				if(zp_get_user_zombie(i)){
					set_msg_block(g_secdeath, BLOCK_SET);
					ExecuteHamB(Ham_TakeDamage, i, 0, id, 200.0, DMG_BLAST);
					set_msg_block(g_secdeath, BLOCK_NOT);
					if(get_user_health(i) <= 0){
						SendDeathMsg(id, i);
					}
				}
			}
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasm32[id]){
		static iclipex = 6
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_M3);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_M3, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M3 && g_hasm32[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(!g_reload[id]){
				if(!zoom[id]){
					cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
					zoom[id] = true
				}
				else if(zoom[id]){
					cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
					zoom[id] = false
				}
			}
		}
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasm32[id]){
		fw_ReloadWeapon_2(weapon_entity)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_ReloadWeapon_2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	new clip, bpammo
	get_user_weapon(id, clip, bpammo);
	if(g_hasm32[id] && clip < 6 && bpammo > 0){
		if(!task_exists(1000)){
			new data[1]
			data[0] = id
			set_task(0.1, "reload", 1000, data, 1);
		}
	}
	if(zoom[id]){
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
		zoom[id] = false
	}
	return HAM_IGNORED
}

public reload(data[]){
	new id = data[0]
	new weapon = find_ent_by_owner(-1, "weapon_m3", id);
	new clip, bpammo, data3[1]
	get_user_weapon(id, clip, bpammo);
	if(!g_reload[id]){
		new data2[1]
		data2[0] = id
		set_weapon_animation(id, 5);
		g_reload[id] = true
		set_pdata_float(id, 83, 27/30.0, 5);
		set_task(1.0, "reload", 1000, data2, 1);
		return
	}
	if(zoom[id]){
		cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
		zoom[id] = false
	}
	if(clip > 5 || bpammo < 1){
		set_weapon_animation(id, 4);
		g_reload[id] = false
		set_pdata_float(id, 83, 1.5, 5);
		return
	}
	cs_set_user_bpammo(id, CSW_M3, bpammo - 1);
	cs_set_weapon_ammo(weapon, clip + 1);
	set_pdata_float(id, 83, 27/30.0, 5);
	set_weapon_animation(id, 3);
	data3[0] = id
	set_task(27/30.0, "reload", 1000, data, 1);
}

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 6666)
	{
		g_hasm32[id] = true;
		g_reload[id] = false
		zoom[id] = false
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_m3.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m3", entity);
	
	if(g_hasm32[owner] && pev_valid(wpn))
	{
		g_hasm32[owner] = false
		g_reload[owner] = false
		zoom[owner] = false
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 6666);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock SendDeathMsg(attacker, victim){ // Sends death message
	message_begin(MSG_BROADCAST, g_secdeath)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("m3") // killer's weapon
	message_end()
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
	write_string(bEnabled ? "bakoweapon_m32" : "weapon_m3");
	write_byte(5);
	write_byte(32);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(5);
	write_byte(21);
	write_byte(0);
	message_end();
}
