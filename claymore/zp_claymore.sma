#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hasmine[33];
new g_weaponmode[33];
new g_exp;
new g_death;
new claymore;
new cvar_damage;
new const g_vmodel[] = "models/v_claymore.mdl"
new const g_pmodel[] = "models/p_claymore.mdl"
new const g_wmodel[] = "models/w_claymore.mdl"

public plugin_init(){
	register_plugin("Claymore Mine MDS", "1.0", "bako35");
	register_clcmd("bakoweapon_claymore", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("HLTV", "NewRound", "a", "1=0", "2=0");
	register_forward(FM_CmdStart, "fw_CmdStart");
	RegisterHam(Ham_Item_Deploy, "weapon_c4", "fw_DeployPost", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_c4", "fw_WeaponIdle", 1);
	register_touch("claymore", "player",  "detonate_mine2");
	g_death = get_user_msgid("DeathMsg");
	cvar_damage = register_cvar("claymore_damage", "1000.0");
	claymore = zp_register_extra_item("Claymore Mine MDS", 0, ZP_TEAM_HUMAN|ZP_TEAM_SURVIVOR);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/claymore_draw.wav");
	precache_sound("weapons/claymore_draw_off.wav");
	precache_sound("weapons/claymore_exp.wav");
	precache_sound("weapons/claymore_shoot.wav");
	precache_sound("weapons/claymore_trigger_off.wav");
	precache_sound("weapons/claymore_trigger_on.wav");
	precache_sound("weapons/claymore_trigger_shoot_on.wav");
	precache_generic("sprites/640hud175x.spr");
	precache_generic("sprites/bakoweapon_claymore.txt");
	g_exp = precache_model("sprites/fexplo.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_c4");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasmine[id] = false
	g_weaponmode[id] = 0
}

public client_disconnect(id){
	g_hasmine[id] = false
	g_weaponmode[id] = 0
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasmine[read_data(2)] = false
	g_weaponmode[read_data(2)] = 0
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hasmine[id] = false
	g_weaponmode[id] = 0
	UTIL_WeaponList(id, false);
}

public NewRound(){
	new ent = find_ent_by_class(-1, "claymore")
	while(ent > 0){
		remove_entity(ent);
		ent = find_ent_by_class(ent, "claymore");
		cs_set_user_bpammo(0, CSW_C4, 0);
		g_hasmine[0] = false
		g_weaponmode[0] = 0
		UTIL_WeaponList(0, false);
	}
}

public zp_extra_item_selected(id, itemid){
	if(itemid == claymore){
		give_mine(id);
	}
}

public give_mine(id){
	if(is_user_alive(id) && !g_hasmine[id]){
		if(user_has_weapon(id, CSW_C4)){
			drop_weapon(id);
		}
		g_hasmine[id] = true
		g_weaponmode[id] = 0
		UTIL_WeaponList(id, true);
		give_item(id, "weapon_c4");
		replace_models(id);
	}
}

public replace_models(id){
	new mine = read_data(2);
	if(g_hasmine[id] && mine == CSW_C4){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_C4) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasmine[id]){
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public plant_mine(data[]){
	new id = data[0]
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
	new ent = create_entity("info_target");
	entity_set_string(ent, EV_SZ_classname, "claymore");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
	entity_set_model(ent, g_wmodel);
	entity_set_size(ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 2.0});
	//entity_set_size(ent, Float:{-100.0, -16.0, 0.0}, Float:{100.0, 16.0, 2.0});
	drop_to_floor(ent);
	g_weaponmode[id] = 1
	set_weapon_animation(id, 9);
	set_pdata_float(id, 83, 31/30.0, 5);
	return PLUGIN_CONTINUE
}

public detonate_mine(data[]){
	new id = data[0]
	new ent = find_ent_by_owner(-1, "claymore", id);
	new Float:fOrigin[3];
	new iOrigin[3];
	static Float:victim = -1
	entity_get_vector(ent, EV_VEC_origin, fOrigin);
	FVecIVec(fOrigin, iOrigin);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
	write_byte(TE_EXPLOSION);
	write_coord(iOrigin[0]);
	write_coord(iOrigin[1]);
	write_coord(iOrigin[2]);
	write_short(g_exp);
	write_byte(32); 
	write_byte(30); 
	write_byte(TE_EXPLFLAG_NOSOUND);
	message_end();
	
	emit_sound(ent, CHAN_VOICE, "weapons/claymore_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fOrigin, 100.0)) != 0){
		if(!is_user_alive(victim) || !zp_get_user_zombie(victim)){
			continue
		}
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHamB(Ham_TakeDamage, victim, 0, id, get_pcvar_float(cvar_damage), DMG_BLAST);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(victim) <= 0){
			SendDeathMsg(id, victim, 0, "claymore");
		}
	}
	remove_entity(ent);
}

public detonate_mine2(ent, id){
	if(!is_valid_ent(ent)){
		return
	}
	new attacker = entity_get_edict(ent, EV_ENT_owner);
	if(g_weaponmode[attacker] != 2){
		return
	}
	if(zp_get_user_zombie(id)){
		new Float:fOrigin[3];
		new iOrigin[3];
		entity_get_vector(ent, EV_VEC_origin, fOrigin);
		FVecIVec(fOrigin, iOrigin);
	
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(TE_EXPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(g_exp);
		write_byte(32); 
		write_byte(30); 
		write_byte(TE_EXPLFLAG_NOSOUND);
		message_end();
	
		emit_sound(ent, CHAN_VOICE, "weapons/claymore_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		new entlist[33];
		new numfound = find_sphere_class(ent, "player", 100.0, entlist, 32);
		for(new i=0;i<numfound;i++){
			new pid = entlist[i];
			if(!is_user_alive(pid) || !zp_get_user_zombie(pid)){
				continue
			}
			set_msg_block(g_death, BLOCK_SET);
			ExecuteHamB(Ham_TakeDamage, pid, 0, attacker, get_pcvar_float(cvar_damage), DMG_BLAST);
			set_msg_block(g_death, BLOCK_NOT);
			if(get_user_health(pid) <= 0){
				SendDeathMsg(attacker, pid, 0, "claymore");
			}
		}
		remove_entity(ent);
		cs_set_user_bpammo(attacker, CSW_C4, 0);
		g_hasmine[attacker] = false
		g_weaponmode[attacker] = 0
		UTIL_WeaponList(attacker, false);
	}
}

public remove_mine(data[]){
	new id = data[0]
	if(g_hasmine[id] && g_weaponmode[id] != 0){
		cs_set_user_bpammo(id, CSW_C4, 0);
		g_hasmine[id] = false
		g_weaponmode[id] = 0
		UTIL_WeaponList(id, false);
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_C4 && g_hasmine[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && !(pev(id, pev_oldbuttons) & IN_ATTACK)){
			new data[1]
			data[0] = id
			if(g_weaponmode[id] == 0){
				set_weapon_animation(id, 1);
				set_task(41/30.0, "plant_mine", .parameter=data, .len=1);
			}
			else if(g_weaponmode[id] != 0){
				if(g_weaponmode[id] == 1){
					set_weapon_animation(id, 7);
				}
				else if(g_weaponmode[id] == 2){
					new ent = find_ent_by_owner(-1, "claymore", id);
					set_weapon_animation(id, 8);
					set_pev(ent, pev_body, 1 * 1 + 1);
				}
				set_task(13/30.0, "detonate_mine", .parameter=data, .len=1);
				set_task(36/30.0, "remove_mine", .parameter=data, .len=1);
			}
		}
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1){
				set_weapon_animation(id, 6);
				g_weaponmode[id] = 2
			}
			else if(g_weaponmode[id] == 2){
				set_weapon_animation(id, 5);
				g_weaponmode[id] = 1
			}
		}
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasmine[id] && g_weaponmode[id] == 0){
		set_weapon_animation(id, 2);
		set_pdata_float(id, 83, 31/30.0, 5);
	}
	else if(g_hasmine[id] && g_weaponmode[id] == 1){ //off
		set_weapon_animation(id, 9);
		set_pdata_float(id, 83, 31/30.0, 5);
	}
	else if(g_hasmine[id] && g_weaponmode[id] == 2){ //on
		set_weapon_animation(id, 10);
		set_pdata_float(id, 83, 31/30.0, 5);
	}
}

public fw_WeaponIdle(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(!is_user_alive(id) || !g_hasmine[id] || get_user_weapon(id) != CSW_C4 || g_weaponmode[id] == 0){
		return HAM_IGNORED
	}
	if(g_hasmine[id] && g_weaponmode[id] == 1 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 3);
		set_pdata_float(weapon_entity, 48, 61/30.0, 4);
		return HAM_SUPERCEDE
	}
	if(g_hasmine[id] && g_weaponmode[id] == 2 && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 4);
		set_pdata_float(weapon_entity, 48, 61/30.0, 4);
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

stock SendDeathMsg(attacker, victim, headshot, const KillersWeapon[]){ // Sends death message
	static bool:kwpn[64]
	format(kwpn, 63, "%s", KillersWeapon);
	
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"))
	write_byte(attacker) // attacker
	write_byte(victim) // victim
	write_byte(headshot) // headshot flag
	write_string(kwpn) // killer's weapon
	message_end()
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_claymore" : "weapon_c4");
	write_byte(14)
	write_byte(1)
	write_byte(-1)
	write_byte(-1)
	write_byte(3)
	write_byte(4)
	write_byte(6)
	write_byte(24)
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
