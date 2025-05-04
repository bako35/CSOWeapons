#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

#define POISON_CLASSNAME "cnpoison"

new g_haspoisongun[33];
new g_poisonammo[33];
new Float:g_punchangles[33];
new cvar_poisongun_damage;
new g_sprite;
new g_death;
new msgid_weaponlist;
new poisongun;
new const g_vmodel[] = "models/v_poisongun.mdl"
new const g_pmodel[] = "models/p_poisongun.mdl"
new const g_wmodel[] = "models/w_poisongun.mdl"
new const g_shootsound[] = "weapons/poisongun-1.wav"
new const g_shootsoundend[] = "weapons/poisongun-2.wav"

public plugin_init() {
	register_plugin("Poison Launcher", "1.0", "bako35");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CMDStart");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_AddToPlayer", 1);
	register_think(POISON_CLASSNAME, "fw_Smoke_Think");
	register_touch(POISON_CLASSNAME, "*", "fw_Smoke_Touch");
	
	cvar_poisongun_damage = register_cvar("poisongun_damage", "100.0");
	g_death = get_user_msgid("DeathMsg");
	msgid_weaponlist = get_user_msgid("WeaponList");
	poisongun = zp_register_extra_item("Poison Launcher", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound(g_shootsoundend);
	precache_sound("weapons/flamegun_clipin1.wav");
	precache_sound("weapons/flamegun_clipin2.wav");
	precache_sound("weapons/flamegun_clipout1.wav");
	precache_sound("weapons/flamegun_clipout2.wav");
	precache_sound("weapons/flamegun_draw.wav");
	precache_model("sprites/ef_smoke_poison.spr");
	precache_generic("sprites/640hud75.spr");
	precache_generic("sprites/bakoweapon_poisongun.txt");
	precache_generic("sprites/poisongun/640hud7.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m249");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_haspoisongun[id] = false
}

public client_disconnect(id){
	g_haspoisongun[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_haspoisongun[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == poisongun){
		give_poisongun(id)
	}
}

public give_poisongun(id){
	if(is_user_alive(id) && !g_haspoisongun[id]){
		if(user_has_weapon(id, CSW_M249)){
			drop_weapon(id);
		}
		give_item(id, "weapon_m249");
		g_haspoisongun[id] = true
		UTIL_WeaponList(id, true);
		cs_set_user_bpammo(id, CSW_M249, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new poisongun = read_data(2);
	if(g_haspoisongun[id] && poisongun == CSW_M249){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_M249) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_CMDStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_haspoisongun[id]){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 1)
		{
			static weapon; weapon = fm_get_user_weapon_entity(id, CSW_M249)
			if(pev_valid(weapon)){
				set_pdata_float(weapon, 48, 2.0, 4)
			}
			set_weapon_animation(id, 2);
			emit_sound(id, CHAN_WEAPON, g_shootsoundend, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
	return FMRES_HANDLED
} 

public fw_PrimaryAttack(weapon_entity){
	new id
	static vecVelocity[3]
	id = get_pdata_cbase(weapon_entity, 41, 5)
	pev(id, pev_velocity, vecVelocity);
	g_poisonammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_haspoisongun[id]){
		return HAM_IGNORED;
	}
	if(!g_poisonammo[id]){
		ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE;
	}
	set_pdata_float(id, 83, 0.1, 5);
	set_weapon_animation(id, 1);
	emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	CreateSmoke(id, 960.0);
	set_pdata_int(weapon_entity, 51, g_poisonammo[id] - 1, 4);
	return HAM_SUPERCEDE;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M249 && g_haspoisongun[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public CreateSmoke(id, Float:speed){
	new idxent
	idxent = create_entity("env_sprite")
	if(!pev_valid(idxent)){
		return
	}
	static Float:vfangle[3], Float:myorigin[3], Float:origin[3], Float:torigin[3], Float:velocity[3]
	get_position(id, 40.0, 5.0, -5.0, origin);
	get_position(id, 1024.0, 0.0, 0.0, torigin);
	pev(id, pev_angles, vfangle);
	pev(id, pev_origin, myorigin);
	vfangle[2] = float(random(18) * 20)
	set_pev(idxent, pev_movetype, MOVETYPE_FLY);
	set_pev(idxent, pev_rendermode, kRenderTransAdd);
	set_pev(idxent, pev_renderamt, 160.0);
	set_pev(idxent, pev_fuser1, halflife_time() + 1.0);
	set_pev(idxent, pev_scale, 0.25);
	set_pev(idxent, pev_nextthink, halflife_time() + 0.05);
	entity_set_string(idxent, EV_SZ_classname, POISON_CLASSNAME);
	engfunc(EngFunc_SetModel, idxent, "sprites/ef_smoke_poison.spr");
	set_pev(idxent, pev_mins, Float:{-1.0, -1.0, -1.0});
	set_pev(idxent, pev_maxs, Float:{1.0, 1.0, 1.0});
	set_pev(idxent, pev_origin, origin);
	set_pev(idxent, pev_gravity, 0.01);
	set_pev(idxent, pev_angles, vfangle);
	set_pev(idxent, pev_solid, SOLID_TRIGGER);
	set_pev(idxent, pev_owner, id);
	set_pev(idxent, pev_frame, 0.0);
	set_pev(idxent, pev_iuser2, get_user_team(id));
	get_speed_vector(origin, torigin, speed, velocity);
	set_pev(idxent, pev_velocity, velocity);
}

public fw_AddToPlayer(weapon_entity, id){
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 67890)
	{
		g_haspoisongun[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[]){
	if(!pev_valid(entity) || !equal(model, "models/w_m249.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m249", entity);
	
	if(g_haspoisongun[owner] && pev_valid(wpn))
	{
		g_haspoisongun[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 67890);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_Smoke_Think(idxent){
	if(!pev_valid(idxent)){
		return
	}
	static Float:fframe, Float:fscale
	pev(idxent, pev_frame, fframe);
	pev(idxent, pev_scale, fscale);
	if(pev(idxent, pev_movetype) == MOVETYPE_NONE){
		fframe += 1.5
		fscale += 0.1
		fscale = floatmin(fscale, 1.75)
		if(fframe > 38.0){
			engfunc(EngFunc_RemoveEntity, idxent);
			return
		}
		set_pev(idxent, pev_nextthink, halflife_time() + 0.025);
	}
	else{
		fframe += 1.75
		fframe = floatmin(38.0, fframe)
		fscale += 0.15
		fscale = floatmin(fscale, 1.75)
		set_pev(idxent, pev_nextthink, halflife_time() + 0.05);
	}
	set_pev(idxent, pev_frame, fframe);
	set_pev(idxent, pev_scale, fscale);
	static Float:ftimeremove
	pev(idxent, pev_fuser1, ftimeremove);
	if(halflife_time() >= ftimeremove){
		engfunc(EngFunc_RemoveEntity, idxent);
		return
	}
}

public fw_Smoke_Touch(ent, id){
	if(!pev_valid(ent)){
		return
	}
	if(pev_valid(id)){
		static classname[32]
		pev(id, pev_classname, classname, sizeof(classname))
		if(equal(classname, POISON_CLASSNAME)){
			return
		}
		else if(is_user_alive(id)){
			if(zp_get_user_zombie(id)){
				static attacker
				attacker = pev(ent, pev_owner)
				if(is_user_connected(attacker)){
					set_msg_block(g_death, BLOCK_SET);
					ExecuteHam(Ham_TakeDamage, id, 0, attacker, get_pcvar_float(cvar_poisongun_damage), DMG_POISON);
					set_msg_block(g_death, BLOCK_NOT);
					if(get_user_health(id) <= 0){
						SendDeathMsg(attacker, id);
					}
				}
			}
		}
	}
	set_pev(ent, pev_movetype, MOVETYPE_NONE);
	set_pev(ent, pev_solid, SOLID_NOT);
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[]){
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3]){
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock SendDeathMsg(attacker, victim){ // Sends death message
	message_begin(MSG_BROADCAST, g_death)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("m249") // killer's weapon
	message_end()
}

stock UTIL_WeaponList(id, const bool: bEnabled)
{
	message_begin(MSG_ONE, msgid_weaponlist, _, id);
	write_string(bEnabled ? "bakoweapon_poisongun" : "weapon_m249");
	write_byte(3);
	write_byte(200);
	write_byte(-1);
	write_byte(-1);
	write_byte(0);
	write_byte(4);
	write_byte(20);
	write_byte(0);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
