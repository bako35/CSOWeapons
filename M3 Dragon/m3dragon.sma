#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>

new g_hasm3dragon[33];
new g_m3dragonammo[33];
new g_secready[33];
new g_secshoot[33];
new g_ammox[33];
new g_spriteright[33];
new g_spriteleft[33];
new g_reload[33];
new g_secdeath;
new g_exp;
new m3dragon;
new const g_vmodel[] = "models/v_m3dragon.mdl"
new const g_pmodel[] = "models/p_m3dragon.mdl"
new const g_wmodel[] = "models/w_m3dragon.mdl"

public plugin_init() {
	register_plugin("M3 Dragon", "1.0", "bako35");
	register_clcmd("gun", "give_m3dragon");
	register_clcmd("bakoweapon_m3dragon", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "fw_ReloadWeapon");
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "fw_ReloadWeapon_2");
	g_secdeath = get_user_msgid("DeathMsg");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_model("models/ef_fireball2.mdl");
	precache_model("models/m3dragon_effect.mdl");
	precache_sound("weapons/m3dragon_after_reload.wav");
	precache_sound("weapons/m3dragon_dragon_fx.wav");
	precache_sound("weapons/m3dragon_exp.wav");
	precache_sound("weapons/m3dragon_fire_loop.wav");
	precache_sound("weapons/m3dragon_reload_insert.wav");
	precache_sound("weapons/m3dragon_secondary_draw.wav");
	precache_sound("weapons/m3dragon_shoot1.wav");
	precache_sound("weapons/m3dragon_shoot2.wav");
	precache_generic("sprites/bakoweapon_m3dragon.txt");
	precache_generic("sprites/m3dragon/640hud7.spr");
	precache_generic("sprites/m3dragon/640hud18.spr");
	precache_generic("sprites/m3dragon/640hud177.spr");
	precache_model("sprites/m3dragon/m3dragon_flame.spr");
	precache_model("sprites/m3dragon/m3dragon_flame2.spr");
	g_exp = precache_model("sprites/fexplo.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m3");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasm3dragon[id] = false
	g_secready[id] = false
	g_secshoot[id] = 0
	g_ammox[id] = 0
	set_sec_ammo(id, g_ammox[id]);
}

public client_disconnect(id){
	g_hasm3dragon[id] = false
	g_secready[id] = false
	g_secshoot[id] = 0
	g_ammox[id] = 0
	set_sec_ammo(id, g_ammox[id]);
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_hasm3dragon[read_data(2)] = false
	g_secready[read_data(2)] = false
	g_secshoot[read_data(2)] = 0
	g_ammox[read_data(2)] = 0
	set_sec_ammo(read_data(2), g_ammox[read_data(2)]);
	UTIL_WeaponList(read_data(2), false);
}

public fw_Spawn(id){
	if(g_hasm3dragon[id] && g_ammox[id] == 1){
		set_sec_ammo(id, g_ammox[id]);
	}
}

public give_m3dragon(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_M3)){
			drop_weapon(id);
		}
		g_hasm3dragon[id] = true
		g_secready[id] = false
		g_secshoot[id] = 0
		g_ammox[id] = 0
		set_sec_ammo(id, g_ammox[id]);
		UTIL_WeaponList(id, true);
		give_item(id, "weapon_m3");
		cs_set_user_bpammo(id, CSW_M3, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new m3dragon = read_data(2);
	if(g_hasm3dragon[id] && m3dragon == CSW_M3){
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
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M3 && g_hasm3dragon[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasm3dragon[id] && !g_secready[id]){
		g_m3dragonammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	else if(g_secready[id]){
		g_m3dragonammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	if(g_reload[id]){
		set_weapon_animation(id, 4);
		set_pdata_float(id, 83, 34/38.0);
		remove_task(1000);
		g_reload[id] = false
		return HAM_SUPERCEDE
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasm3dragon[id] && g_m3dragonammo[id]){
		set_pdata_float(id, 83, 1.1, 5);
		emit_sound(id, CHAN_WEAPON, "weapons/m3dragon_shoot1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, random_num(1, 2));
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M3 && g_hasm3dragon[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_secready[id] && g_ammox[id] == 1){
				emit_sound(id, CHAN_WEAPON, "weapons/m3dragon_shoot2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				set_weapon_animation(id, 8);
				dragon_fireball(id);
				g_secready[id] = false
				g_secshoot[id] = 0
				g_ammox[id] = 0
				set_sec_ammo(id, g_ammox[id]);
				if(pev_valid(g_spriteleft[id]) && pev_valid(g_spriteright[id])){
					engfunc(EngFunc_RemoveEntity, g_spriteleft[id]);
					engfunc(EngFunc_RemoveEntity, g_spriteright[id]);
					
				}
			}
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage){
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_M3 && g_hasm3dragon[attacker]){
		g_secshoot[attacker] += 1
		if(g_secshoot[attacker] >= 8 && g_ammox[attacker] != 1){
			g_secready[attacker] = true
			g_ammox[attacker] = 1
			set_sec_ammo(attacker, g_ammox[attacker]);
			fireweapon_left(attacker);
			fireweapon_right(attacker);
		}
	}
}

public dragon_fireball(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "dragon_fireball");
	entity_set_model(rocket, "models/ef_fireball2.mdl");
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
}

public pfn_touch(ptr, ptd){
	if(is_valid_ent(ptr)){
		new id
		id = entity_get_edict(ptr, EV_ENT_owner)
		new classname[32]
		entity_get_string(ptr, EV_SZ_classname, classname, 31);
		if(equal(classname, "dragon_fireball")){
			static Float:attacker
			attacker = pev(ptr, pev_owner)
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			emit_sound(ptr, CHAN_VOICE, "weapons/m3dragon_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			spawn_dragon(id);
			radius(ptr);
			remove_entity(ptr);
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iorigin)
			write_byte(TE_EXPLOSION)
			write_coord(iorigin[0])
			write_coord(iorigin[1])
			write_coord(iorigin[2])
			write_short(g_exp)
			write_byte(30)
			write_byte(20)
			write_byte(TE_EXPLFLAG_NOSOUND)
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

public spawn_dragon(id){
	new Float:origin[3]
	new ent
	new ent2
	new data[1]
	ent = create_entity("info_target");
	ent2 = find_ent_by_class(-1, "dragon_fireball");
	data[0] = ent
	if(!ent2){
		client_print(id, print_chat, "Nie znaleziono entity!");
		return PLUGIN_HANDLED_MAIN;
	}
	entity_get_vector(ent2, EV_VEC_origin, origin);
	if(!ent){
		client_print(id, print_chat, "Nie utworzono entity!");
		return PLUGIN_HANDLED_MAIN;
	}
	entity_set_string(ent ,EV_SZ_classname, "dragon");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent, "models/m3dragon_effect.mdl");
	entity_set_float(ent, EV_FL_frame, 0);
	entity_set_int(ent, EV_INT_body, 3);
	entity_set_float(ent, EV_FL_framerate, 1.0);
	entity_set_float(ent, EV_FL_animtime, halflife_time());
	set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 128);
	set_task(90/30.0, "destroy_dragon", .parameter=data, .len=1);
	return PLUGIN_CONTINUE
}

public radius(entity){
	new id = entity_get_edict(entity, EV_ENT_owner)
	for(new i = 1; i < 33; i++){
		if(is_user_alive(i)){
			new data[2]
			new distance
			distance = floatround(entity_range(entity, i))
			data[0] = id
			data[1] = i
			if(distance <= 150){
				if(get_user_team(id) != get_user_team(i)){
					set_task(0.1, "dragon_damage", 2000, data, 2, "a", 30);
				}
			}
		}
	}
}

public destroy_dragon(data[]){
	new ient
	ient = data[0]
	engfunc(EngFunc_RemoveEntity, ient);
	remove_task(1500);
}

public dragon_damage(data[]){
	new attid = data[0]
	new vicid = data[1]
	static weapon_entity
	weapon_entity = fm_find_ent_by_owner(-1, "weapon_m3", attid)
	if(pev_valid(weapon_entity)){
		ExecuteHam(Ham_TakeDamage, vicid, weapon_entity, attid, 2.0, DMG_BURN|DMG_NEVERGIB);
	}
	else{
		ExecuteHam(Ham_TakeDamage, vicid, 0, attid, 2.0, DMG_BURN|DMG_NEVERGIB);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 666666)
	{
		g_hasm3dragon[id] = true;
		g_secshoot[id] = 0
		g_reload[id] = false
		if(pev(weapon_entity, pev_iuser4) == 1){
			g_ammox[id] = pev(weapon_entity, pev_iuser4)
			set_sec_ammo(id, g_ammox[id]);
			g_secready[id] = true
		}
		else{
			g_ammox[id] = 0
			set_sec_ammo(id, g_ammox[id]);
			g_secready[id] = false
		}
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_m3.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m3", entity);
	
	if(g_hasm3dragon[owner] && pev_valid(wpn))
	{
		g_hasm3dragon[owner] = false;
		g_secready[owner] = false;
		g_secshoot[owner] = 0
		g_reload[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 666666);
		set_pev(wpn, pev_iuser4, g_ammox[owner]);
		g_ammox[owner] = 0
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasm3dragon[id]){
		fw_ReloadWeapon_2(weapon_entity)
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_ReloadWeapon_2(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	new clip, bpammo
	get_user_weapon(id, clip, bpammo);
	if(g_hasm3dragon[id] && clip < 8 && bpammo > 0){
		if(!task_exists(1000)){
			new data[1]
			data[0] = id
			set_task(0.1, "reload", 1000, data, 1);
		}
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
		set_pdata_float(id, 83, 16/30.0, 5);
		set_task(1.0, "reload", 1000, data2, 1);
		return
	}
	if(clip > 7 || bpammo < 1){
		set_weapon_animation(id, 4);
		g_reload[id] = false
		set_pdata_float(id, 83, 1.5, 5);
		return
	}
	cs_set_user_bpammo(id, CSW_M3, bpammo - 1);
	cs_set_weapon_ammo(weapon, clip + 1);
	set_pdata_float(id, 83, 28/65.0, 5);
	set_weapon_animation(id, 3);
	data3[0] = id
	set_task(28/65.0, "reload", 1000, data, 1);
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_m3dragon" : "weapon_m3");
	write_byte(5)
	write_byte(32)
	write_byte(bEnabled ? 1 : -1)
	write_byte(bEnabled ? 1 : -1)
	write_byte(0)
	write_byte(5)
	write_byte(21)
	write_byte(0)
	message_end();
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock set_sec_ammo(id, const SecAmmo){
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id);
	write_byte(1);
	write_byte(SecAmmo);
	message_end();
}

stock fireweapon_right(id){
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100){
		return FM_NULLENT
	}
	static allocstringcached
	if(allocstringcached || (allocstringcached = engfunc(EngFunc_AllocString, "env_sprite"))){
		g_spriteright[id] = engfunc(EngFunc_CreateNamedEntity, allocstringcached);
	}
	if(!pev_valid(g_spriteright[id])){
		return FM_NULLENT
	}
	set_pev(g_spriteright[id], pev_model, "sprites/m3dragon/m3dragon_flame2.spr");
	set_pev(g_spriteright[id], pev_classname, "fireweapon_right");
	set_pev(g_spriteright[id], pev_owner, id);
	set_pev(g_spriteright[id], pev_aiment, id);
	set_pev(g_spriteright[id], pev_body, 4);
	set_pev(g_spriteright[id], pev_frame, 0.0);
	set_pev(g_spriteright[id], pev_rendermode, kRenderTransAdd);
	set_pev(g_spriteright[id], pev_rendercolor, Float:{0.0, 0.0, 0.0});
	set_pev(g_spriteright[id], pev_renderamt, Float: 255.0);
	set_pev(g_spriteright[id], pev_renderfx, kRenderFxNone);
	set_pev(g_spriteright[id], pev_framerate, 20.0);
	set_pev(g_spriteright[id], pev_scale, 0.08);
	set_pev(g_spriteright[id], pev_fuser2, halflife_time() + 40.0);
	set_pev(g_spriteright[id], pev_nextthink, halflife_time() + 0.01);
	dllfunc(DLLFunc_Spawn, g_spriteright[id]);
	return g_spriteright[id]
}

stock fireweapon_left(id){
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < 100){
		return FM_NULLENT
	}
	static allocstringcached
	if(allocstringcached || (allocstringcached = engfunc(EngFunc_AllocString, "env_sprite"))){
		g_spriteleft[id] = engfunc(EngFunc_CreateNamedEntity, allocstringcached);
	}
	if(!pev_valid(g_spriteleft[id])){
		return FM_NULLENT
	}
	set_pev(g_spriteleft[id], pev_model, "sprites/m3dragon/m3dragon_flame.spr");
	set_pev(g_spriteleft[id], pev_classname, "fireweapon_left");
	set_pev(g_spriteleft[id], pev_owner, id);
	set_pev(g_spriteleft[id], pev_aiment, id);
	set_pev(g_spriteleft[id], pev_body, 3);
	set_pev(g_spriteleft[id], pev_frame, 0.0);
	set_pev(g_spriteleft[id], pev_rendermode, kRenderTransAdd);
	set_pev(g_spriteleft[id], pev_rendercolor, Float:{0.0, 0.0, 0.0});
	set_pev(g_spriteleft[id], pev_renderamt, 255.0);
	set_pev(g_spriteleft[id], pev_renderfx, kRenderFxNone);
	set_pev(g_spriteleft[id], pev_framerate, 20.0);
	set_pev(g_spriteleft[id], pev_scale, 0.08);
	set_pev(g_spriteleft[id], pev_fuser1, halflife_time() + 40.0);
	set_pev(g_spriteleft[id], pev_nextthink, halflife_time() + 0.01);
	dllfunc(DLLFunc_Spawn, g_spriteleft[id]);
	return g_spriteleft[id]
}
