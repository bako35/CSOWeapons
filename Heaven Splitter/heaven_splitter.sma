#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

new g_haswonder[33];
new g_wonderammo[33];
new g_weaponmode[33];
new ammox[33];
new blood_spr[2];
new g_exp1;
new g_exp2;
new g_exp3;
new g_exp4;
new g_death;
new const g_vmodel[] = "models/v_wondercannon.mdl"
new const g_pmodel[] = "models/p_wondercannon.mdl"
new const g_wmodel[] = "models/w_all_models.mdl"

public plugin_init() {
	register_plugin("Heaven Splitter", "1.0", "bako35");
	register_clcmd("gun", "give_wonder");
	register_clcmd("say /ammo", "give_wonder_ammo");
	register_clcmd("bakoweapon_wondercannon", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_PostFrame, "weapon_galil", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_galil", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_galil", "fw_WeaponIdle", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	g_death = get_user_msgid("DeathMsg");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_model("models/bomb_wondercannon.mdl");
	precache_model("models/ef_wondercannon_area.mdl");
	precache_sound("weapons/wondercannon_bomd_exp.wav");
	precache_sound("weapons/wondercannon_bomd_exp2.wav");
	precache_sound("weapons/wondercannon_bomd_on.wav");
	precache_sound("weapons/wondercannon_bomd_on_exp.wav");
	precache_sound("weapons/wondercannon_clipin1.wav");
	precache_sound("weapons/wondercannon_clipout1.wav");
	precache_sound("weapons/wondercannon_cmod_charging.wav");
	precache_sound("weapons/wondercannon_comd_exp.wav");
	precache_sound("weapons/wondercannon_comd_shoot.wav");
	precache_sound("weapons/wondercannon_comd_start.wav");
	precache_sound("weapons/wondercannon_draw.wav");
	precache_sound("weapons/wondercannon-1.wav");
	precache_generic("sprites/bakoweapon_wondercannon.txt");
	precache_generic("sprites/640hud193.spr");
	precache_generic("sprites/640hud38.spr");
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");
	g_exp1 = precache_model("sprites/ef_wondercannon_hit1_fx.spr");
	g_exp2 = precache_model("sprites/ef_wondercannon_hit2_fx.spr");
	g_exp3 = precache_model("sprites/ef_wondercannon_hit3_fx.spr");
	g_exp4 = precache_model("sprites/ef_wondercannon_hit4_fx.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_galil");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_haswonder[id] = false
	g_weaponmode[id] = 0
}

public client_disconnect(id){
	g_haswonder[id] = false
	g_weaponmode[id] = 0
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_haswonder[read_data(2)] = false
	g_weaponmode[read_data(2)] = 0
	UTIL_WeaponList(read_data(2), false);
}

public give_wonder(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_GALIL)){
			drop_weapon(id);
		}
		g_haswonder[id] = true
		g_weaponmode[id] = 1
		ammox[id] = 3
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_galil");
		cs_set_weapon_ammo(wpnid, 30);
		cs_set_user_bpammo(id, CSW_GALIL, 200);
		set_sec_ammo(id, ammox[id]);
		replace_models(id);
	}
}

public give_wonder_ammo(id){
	if(is_user_alive(id) && g_haswonder[id] && ammox[id] < 3){
		ammox[id] = 3
		set_sec_ammo(id, ammox[id]);
		cs_set_user_bpammo(id, CSW_GALIL, 200);
		client_cmd(id, "spk items/9mmclip1.wav");
	}
}

public replace_models(id){
	new wonder = read_data(2);
	if(g_haswonder[id] && wonder == CSW_GALIL){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_GALIL) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	g_wonderammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_haswonder[id]){
		return HAM_IGNORED
	}
	if(!g_wonderammo[id]){
		ExecuteHamB(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE
	}
	if(g_weaponmode[id] == 1){
		set_pdata_float(id, 83, 31/30.0, 5);
		set_pdata_float(weapon_entity, 46, 31/30.0, 4);
		set_pdata_float(weapon_entity, 48, 31/30 + 0.5, 4);
		set_weapon_animation(id, random_num(3, 5));
		emit_sound(id, CHAN_WEAPON, "weapons/wondercannon-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_int(weapon_entity, 51, g_wonderammo[id] - 1, 4);
		UTIL_MakeBloodAndBulletHoles(id);
	}
	else if(g_weaponmode[id] == 2 && ammox[id] <= 3 && ammox[id] > 0){
		set_pdata_float(id, 83, 31/30.0, 5);
		set_pdata_float(weapon_entity, 46, 31/30.0, 4);
		set_pdata_float(weapon_entity, 48, 31/30 + 0.5, 4);
		set_weapon_animation(id, 9);
		emit_sound(id, CHAN_WEAPON, "weapons/wondercannon_comd_shoot.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		ammox[id] -= 1
		set_sec_ammo(id, ammox[id]);
		launchershoot(id);
		g_weaponmode[id] = 1
	}
	return HAM_SUPERCEDE
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_GALIL && g_haswonder[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage){
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GALIL && g_haswonder[attacker]){
		SetHamParamFloat(4, 1.0);
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_haswonder[id]){
		static iclipex = 30
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_GALIL);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_GALIL, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public explosions(data[]){
	new attacker = data[0];
	new victim = data[1];
	new vorigin[3];
	new randomnum = random_num(1, 4);
	get_user_origin(victim, vorigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vorigin)
	write_byte(TE_EXPLOSION)
	write_coord(vorigin[0])
	write_coord(vorigin[1])
	write_coord(vorigin[2])
	write_short(randomnum == 1 ? g_exp1 : (randomnum == 2 ? g_exp2 : (randomnum == 3 ? g_exp3 : g_exp4)))
	write_byte(15)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	emit_sound(victim, CHAN_ITEM, "weapons/wondercannon_bomd_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	ExecuteHam(Ham_TakeDamage, victim, 0, attacker, 10.0, DMG_BLAST|DMG_NEVERGIB);
	if(!is_user_alive(victim)){
		SendDeathMsg(attacker, victim, 0, "galil");
		//remove_task(1000);
	}
	if(!is_user_connected(victim)){
		remove_task(1000);
	}
}

public launchershoot(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "wonder_mine");
	entity_set_model(rocket, "models/bomb_wondercannon.mdl");
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
		new classname[32];
		entity_get_string(ptr, EV_SZ_classname, classname, 31);
		if(equal(classname, "wonder_mine")){
			static Float:attacker
			attacker = pev(ptr, pev_owner)
			new Float:forigin[3]
			new iorigin[3]
			new ent = find_ent_by_owner(-1, "heaven_mine_1", attacker);
			new ent2 = find_ent_by_owner(-1, "heaven_mine_2", attacker);
			new ent3 = find_ent_by_owner(-1, "heaven_mine_3", attacker);
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			if(!pev_valid(ent)){
				spawn_wondermine_1(attacker);
			}
			else if(!pev_valid(ent2)){
				spawn_wondermine_2(attacker);
			}
			else if(!pev_valid(ent3)){
				spawn_wondermine_3(attacker);
			}
			remove_entity(ptr);
			if(is_valid_ent(ptd)){
				new classname2[32];
				entity_get_string(ptd, EV_SZ_classname, classname, 31);
				if(equal(classname2, "func_breakable")){
					force_use(ptr, ptd);
				}
				remove_entity(ptr);
			}
		}
	}
	return PLUGIN_CONTINUE
}		

public spawn_wondermine_1(id){
	new Float:origin[3];
	new ent, ent2, before_ent
	ent = create_entity("info_target"); //mine
	ent2 = create_entity("info_target"); //effect area
	before_ent = find_ent_by_owner(-1, "wonder_mine", id);
	if(!pev_valid(before_ent)){
		client_print(id, print_chat, "Nie znaleziono wypuszczonej miny!");
		return PLUGIN_HANDLED_MAIN
	}
	entity_get_vector(before_ent, EV_VEC_origin, origin);
	if(!pev_valid(ent)){ //mine
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent2)){ //effect area
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	//mine
	entity_set_string(ent ,EV_SZ_classname, "heaven_mine_1");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent, "models/bomb_wondercannon.mdl");
	entity_set_float(ent, EV_FL_frame, 0);
	entity_set_int(ent, EV_INT_body, 3);
	entity_set_float(ent, EV_FL_framerate, 1.0);
	entity_set_float(ent, EV_FL_animtime, halflife_time());
	entity_set_size(ent, Float:{-16.0,-16.0,0.0}, Float:{16.0,16.0,2.0});
	drop_to_floor(ent);
	//effect area
	entity_set_string(ent2 ,EV_SZ_classname, "effect_area_1");
	entity_set_edict(ent2 ,EV_ENT_owner, id);
	entity_set_int(ent2, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent2, origin);
	entity_set_int(ent2, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent2, "models/ef_wondercannon_area.mdl");
	entity_set_float(ent2, EV_FL_frame, 0);
	entity_set_int(ent2, EV_INT_body, 3);
	entity_set_float(ent2, EV_FL_framerate, 1.0);
	entity_set_float(ent2, EV_FL_animtime, halflife_time());
	entity_set_size(ent2, Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0});
	drop_to_floor(ent2);
	return PLUGIN_CONTINUE
}

public spawn_wondermine_2(id){
	new Float:origin[3];
	new ent, ent2, before_ent
	ent = create_entity("info_target"); //mine
	ent2 = create_entity("info_target"); //effect area
	before_ent = find_ent_by_owner(-1, "wonder_mine", id);
	if(!pev_valid(before_ent)){
		client_print(id, print_chat, "Nie znaleziono wypuszczonej miny!");
		return PLUGIN_HANDLED_MAIN
	}
	entity_get_vector(before_ent, EV_VEC_origin, origin);
	if(!pev_valid(ent)){ //mine
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent2)){ //effect area
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	//mine
	entity_set_string(ent ,EV_SZ_classname, "heaven_mine_2");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent, "models/bomb_wondercannon.mdl");
	entity_set_float(ent, EV_FL_frame, 0);
	entity_set_int(ent, EV_INT_body, 3);
	entity_set_float(ent, EV_FL_framerate, 1.0);
	entity_set_float(ent, EV_FL_animtime, halflife_time());
	entity_set_size(ent, Float:{-16.0,-16.0,0.0}, Float:{16.0,16.0,2.0});
	drop_to_floor(ent);
	//effect area
	entity_set_string(ent2 ,EV_SZ_classname, "effect_area_2");
	entity_set_edict(ent2 ,EV_ENT_owner, id);
	entity_set_int(ent2, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent2, origin);
	entity_set_int(ent2, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent2, "models/ef_wondercannon_area.mdl");
	entity_set_float(ent2, EV_FL_frame, 0);
	entity_set_int(ent2, EV_INT_body, 3);
	entity_set_float(ent2, EV_FL_framerate, 1.0);
	entity_set_float(ent2, EV_FL_animtime, halflife_time());
	entity_set_size(ent2, Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0});
	drop_to_floor(ent2);
	return PLUGIN_CONTINUE
}

public spawn_wondermine_3(id){
	new Float:origin[3];
	new ent, ent2, before_ent
	ent = create_entity("info_target"); //mine
	ent2 = create_entity("info_target"); //effect area
	before_ent = find_ent_by_owner(-1, "wonder_mine", id);
	if(!pev_valid(before_ent)){
		client_print(id, print_chat, "Nie znaleziono wypuszczonej miny!");
		return PLUGIN_HANDLED_MAIN
	}
	entity_get_vector(before_ent, EV_VEC_origin, origin);
	if(!pev_valid(ent)){ //mine
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent2)){ //effect area
		client_print(id, print_chat, "Can't create entity!");
		return PLUGIN_HANDLED_MAIN
	}
	//mine
	entity_set_string(ent ,EV_SZ_classname, "heaven_mine_3");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent, "models/bomb_wondercannon.mdl");
	entity_set_float(ent, EV_FL_frame, 0);
	entity_set_int(ent, EV_INT_body, 3);
	entity_set_float(ent, EV_FL_framerate, 1.0);
	entity_set_float(ent, EV_FL_animtime, halflife_time());
	entity_set_size(ent, Float:{-16.0,-16.0,0.0}, Float:{16.0,16.0,2.0});
	drop_to_floor(ent);
	//effect area
	entity_set_string(ent2 ,EV_SZ_classname, "effect_area_3");
	entity_set_edict(ent2 ,EV_ENT_owner, id);
	entity_set_int(ent2, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_origin(ent2, origin);
	entity_set_int(ent2, EV_INT_solid, SOLID_NOT);
	entity_set_model(ent2, "models/ef_wondercannon_area.mdl");
	entity_set_float(ent2, EV_FL_frame, 0);
	entity_set_int(ent2, EV_INT_body, 3);
	entity_set_float(ent2, EV_FL_framerate, 1.0);
	entity_set_float(ent2, EV_FL_animtime, halflife_time());
	entity_set_size(ent2, Float:{0.0,0.0,0.0}, Float:{0.0,0.0,0.0});
	drop_to_floor(ent2);
	return PLUGIN_CONTINUE
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_haswonder[id]){
		set_pdata_float(id, 46, 61/30.0, 4);
		set_pdata_float(id, 47, 61/30.0, 4);
		set_pdata_float(id, 48, 61/30.0, 4);
		set_pdata_float(id, 83, 61/30.0, 5);
		g_weaponmode[id] = 1
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if((is_user_alive(id) && get_user_weapon(id) == CSW_GALIL) && g_haswonder[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1 && ammox[id] > 0){
				set_weapon_animation(id, 7);
				set_pdata_float(id, 83, 31/30.0, 5);
				g_weaponmode[id] = 2
			}
			else if(ammox[id] == 0){
				new ent = find_ent_by_owner(-1, "heaven_mine_1", id);
				new ent2 = find_ent_by_owner(-1, "heaven_mine_2", id);
				new ent3 = find_ent_by_owner(-1, "heaven_mine_3", id);
				if(pev_valid(ent) && pev_valid(ent2) && pev_valid(ent3)){
					new data[1]
					data[0] = id
					set_weapon_animation(id, 6);
					set_pdata_float(id, 83, 46/30.0, 5);
					set_task(24/30.0, "detonate_wondermine", 2000, data, 1);
				}
				else{
					emit_sound(id, CHAN_VOICE, "common/wpn_denyselect.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					
				}
			}
		}
	}
}

public detonate_wondermine(data[]){
	new attacker = data[0]
	new ent = find_ent_by_owner(-1, "heaven_mine_1", attacker);
	new ent2 = find_ent_by_owner(-1, "heaven_mine_2", attacker);
	new ent3 = find_ent_by_owner(-1, "heaven_mine_3", attacker);
	new ent_effect1 = find_ent_by_owner(-1, "effect_area_1", attacker);
	new ent_effect2 = find_ent_by_owner(-1, "effect_area_2", attacker);
	new ent_effect3 = find_ent_by_owner(-1, "effect_area_3", attacker);
	if(!pev_valid(ent)){
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent2)){
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent3)){
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent_effect1)){
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent_effect2)){
		return PLUGIN_HANDLED_MAIN
	}
	if(!pev_valid(ent_effect3)){
		return PLUGIN_HANDLED_MAIN
	}
	new Float:forigin_1[3];
	new Float:forigin_2[3];
	new Float:forigin_3[3];
	new iorigin_1[3], iorigin_2[3], iorigin_3[3];
	entity_get_vector(ent, EV_VEC_origin, forigin_1);
	entity_get_vector(ent2, EV_VEC_origin, forigin_2);
	entity_get_vector(ent3, EV_VEC_origin, forigin_3);
	FVecIVec(forigin_1, iorigin_1);
	FVecIVec(forigin_2, iorigin_2);
	FVecIVec(forigin_3, iorigin_3);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iorigin_1)
	write_byte(TE_EXPLOSION)
	write_coord(iorigin_1[0])
	write_coord(iorigin_1[1])
	write_coord(iorigin_1[2])
	write_short(g_exp4)
	write_byte(15)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iorigin_2)
	write_byte(TE_EXPLOSION)
	write_coord(iorigin_2[0])
	write_coord(iorigin_2[1])
	write_coord(iorigin_2[2])
	write_short(g_exp4)
	write_byte(15)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, iorigin_3)
	write_byte(TE_EXPLOSION)
	write_coord(iorigin_3[0])
	write_coord(iorigin_3[1])
	write_coord(iorigin_3[2])
	write_short(g_exp4)
	write_byte(15)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	emit_sound(ent, CHAN_VOICE, "weapons/wondercannon_comd_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	emit_sound(ent2, CHAN_VOICE, "weapons/wondercannon_comd_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	emit_sound(ent3, CHAN_VOICE, "weapons/wondercannon_comd_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	for(new i = 1; i < 33; i++){
		if(is_user_alive(i)){
			new distance_1 = floatround(entity_range(ent, i));
			new distance_2 = floatround(entity_range(ent2, i));
			new distance_3 = floatround(entity_range(ent3, i));
			if(distance_1 <= 75 && get_user_team(attacker) != get_user_team(i)){
				set_msg_block(g_death, BLOCK_SET);
				ExecuteHam(Ham_TakeDamage, i, 0, attacker, 200.0, DMG_BLAST);
				set_msg_block(g_death, BLOCK_NOT);
			}
			else if(distance_2 <= 75 && get_user_team(attacker) != get_user_team(i)){
				set_msg_block(g_death, BLOCK_SET);
				ExecuteHam(Ham_TakeDamage, i, 0, attacker, 200.0, DMG_BLAST);
				set_msg_block(g_death, BLOCK_NOT);
			}
			else if(distance_3 <= 75 && get_user_team(attacker) != get_user_team(i)){
				set_msg_block(g_death, BLOCK_SET);
				ExecuteHam(Ham_TakeDamage, i, 0, attacker, 200.0, DMG_BLAST);
				set_msg_block(g_death, BLOCK_NOT);
			}
			if(!is_user_alive(i)){
				SendDeathMsg(attacker, i, 0, "galil");
			}
		}
	}
	remove_entity(ent);
	remove_entity(ent2);
	remove_entity(ent3);
	remove_entity(ent_effect1);
	remove_entity(ent_effect2);
	remove_entity(ent_effect3);
}

public fw_WeaponIdle(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!is_user_alive(id) || !g_haswonder[id] || get_user_weapon(id) != CSW_GALIL || g_weaponmode[id] != 2){
		return HAM_IGNORED
	}
	if(g_haswonder[id] && g_weaponmode[id] == 2 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 8);
		set_pdata_float(weapon_entity, 48, 111/30.0, 4);
		return HAM_SUPERCEDE
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 66666)
	{
		g_haswonder[id] = true;
		g_weaponmode[id] = 1
		set_pev(weapon_entity, pev_impulse, 0);
		ammox[id] = pev(weapon_entity, pev_iuser4);
		set_sec_ammo(id, ammox[id]);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_galil.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_galil", entity);
	
	if(g_haswonder[owner] && pev_valid(wpn))
	{
		g_haswonder[owner] = false;
		g_weaponmode[owner] = 0
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 66666);
		set_pev(wpn, pev_iuser4, ammox[owner]);
		ammox[owner] = 0
		set_sec_ammo(owner, ammox[owner]);
		//set_pev(wpn, pev_skin, 36);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock set_sec_ammo(id, const SecAmmo){
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id);
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
   new aimOrigin[3], target, body, data[2]
   get_user_origin(id, aimOrigin, 3)
   get_user_aiming(id, target, body)
   
   if(target > 0 && target <= get_maxplayers())
   {
   static Float:plrViewAngles[3], Float:VecEnd[3], Float:VecDir[3], Float:PlrOrigin[3];
   pev(id, pev_v_angle, plrViewAngles);

   static Float:VecSrc[3], Float:VecDst[3];
   
   pev(id, pev_origin, PlrOrigin)
   pev(id, pev_view_ofs, VecSrc)
   xs_vec_add(VecSrc, PlrOrigin, VecSrc)

   angle_vector(plrViewAngles, ANGLEVECTOR_FORWARD, VecDir);
   xs_vec_mul_scalar(VecDir, 8192.0, VecDst);
   xs_vec_add(VecDst, VecSrc, VecDst);
   
   new hTrace = create_tr2()
   engfunc(EngFunc_TraceLine, VecSrc, VecDst, 0, id, hTrace)
   new hitEnt = get_tr2(hTrace, TR_pHit);
   get_tr2(hTrace, TR_vecEndPos, VecEnd);
      
   if(pev_valid(hitEnt)){
      new Float:takeDamage;
      pev(hitEnt, pev_takedamage, takeDamage);

      new Float:dmg = 1.0

      new hitGroup = get_tr2(hTrace, TR_iHitgroup);

      switch (hitGroup){
         case HIT_HEAD: {dmg *= 3.0;}
         case HIT_LEFTARM: {dmg *= 1.0;}
         case HIT_RIGHTARM: {dmg *= 1.0;}
         case HIT_LEFTLEG: {dmg *= 1.0;}
         case HIT_RIGHTLEG: {dmg *= 1.0;}
      }
      data[0] = id
      data[1] = hitEnt
      if(is_user_connected(hitEnt) && cs_get_user_team(id) != cs_get_user_team(hitEnt)){
      	ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg, DMG_BULLET|DMG_NEVERGIB);
	ExecuteHam(Ham_TraceBleed, hitEnt, dmg, VecDir, hTrace, DMG_BULLET|DMG_NEVERGIB);
	make_blood(VecEnd, dmg, hitEnt);
	set_task(0.5, "explosions", 1000, data, 2, "a", 5);
      }
	}
   }
}

stock make_blood(const Float:vTraceEnd[3], Float:Damage, hitEnt) {
   new bloodColor = ExecuteHam(Ham_BloodColor, hitEnt);
   if (bloodColor == -1)
      return;

   new amount = floatround(Damage);

   amount *= 2;

   message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
   write_byte(TE_BLOODSPRITE);
   write_coord(floatround(vTraceEnd[0]));
   write_coord(floatround(vTraceEnd[1]));
   write_coord(floatround(vTraceEnd[2]));
   write_short(blood_spr[1]);
   write_short(blood_spr[0]);
   write_byte(bloodColor);
   write_byte(min(max(3, amount/10), 16));
   message_end();
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_wondercannon" : "weapon_galil");
	write_byte(4);
	write_byte(90);
	write_byte(bEnabled ? 1 : -1);
	write_byte(bEnabled ? 3 : -1);
	write_byte(0);
	write_byte(17);
	write_byte(14);
	write_byte(0);
	message_end();
}

stock SendDeathMsg(attacker, victim, headshot, const KillersWeapon[]){ // Sends death message
	static bool:kwpn[64]
	format(kwpn, 63, "%s", KillersWeapon);
	
	message_begin(MSG_BROADCAST, g_death)
	write_byte(attacker) // attacker
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag
	write_string(kwpn) // killer's weapon
	message_end()
}
