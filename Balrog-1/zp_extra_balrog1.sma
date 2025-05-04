#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hasbalrog1[33];
new g_balrog1sec[33];
new g_balrog1ammo[33];
new blood_spr[2];
new g_explode;
new g_death;
new g_score;
new msgid_weaponlist;
new balrog1;
new cvar_balrog1sec_damage;
new cvar_balrog1sec_radius;

new const g_vmodel[] = "models/v_balrog1.mdl"
new const g_pmodel[] = "models/p_balrog1.mdl"
new const g_wmodel[] = "models/w_balrog1.mdl"
new const g_shootsound1[] = "weapons/balrog1-1.wav"
new const g_shootsound2[] = "weapons/balrog1-2.wav"
new const gunshut_decals[] = {41, 42, 43, 44, 45}

public plugin_init() {
	register_plugin("[ZP] Extra Item: Balrog-1", "1.1", "bako35");
	register_clcmd("bakoweapon_balrog1", "HookWeapon");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_deagle", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_deagle", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	
	g_death = get_user_msgid("DeathMsg");
	g_score = get_user_msgid("ScoreInfo");
	msgid_weaponlist = get_user_msgid("WeaponList");
	cvar_balrog1sec_damage = register_cvar("balrog1_secondary_damage", "100.0");
	cvar_balrog1sec_radius = register_cvar("balrog1_secondary_radius", "75.0");
	balrog1 = zp_register_extra_item("Balrog-1", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound1);
	precache_sound(g_shootsound2);
	precache_sound("weapons/balrog1_changea.wav");
	precache_sound("weapons/balrog1_changeb.wav");
	precache_sound("weapons/balrog1_draw.wav");
	precache_sound("weapons/balrog1_reload.wav");
	precache_sound("weapons/balrog1_reloadb.wav");
	precache_generic("sprites/640hud83.spr");
	precache_generic("sprites/balrog1/640hud4.spr");
	precache_generic("sprites/bakoweapon_balrog1.txt");
	g_explode = precache_model("sprites/ef_balrog1.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_deagle");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasbalrog1[id] = false
	g_balrog1sec[id] = false
}

public client_disconnect(id){
	g_hasbalrog1[id] = false
	g_balrog1sec[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasbalrog1[read_data(2)] = false
	g_balrog1sec[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == balrog1){
		give_balrog1(id);
	}
}

public give_balrog1(id){
	if(is_user_alive(id) && !g_hasbalrog1[id]){
		if(user_has_weapon(id, CSW_DEAGLE)){
			drop_weapon(id);
		}
		g_hasbalrog1[id] = true
		UTIL_WeaponList(id, true);
		new wpnid
		wpnid = give_item(id, "weapon_deagle");
		cs_set_weapon_ammo(wpnid, 10);
		cs_set_user_bpammo(id, CSW_DEAGLE, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new balrog1 = read_data(2);
	if(g_hasbalrog1[id] && balrog1 == CSW_DEAGLE){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_DEAGLE) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasbalrog1[id]){
		g_balrog1ammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasbalrog1[id] && g_balrog1ammo[id] && !g_balrog1sec[id]){
		emit_sound(id, CHAN_WEAPON, g_shootsound1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 2);
		set_pdata_float(id, 83, 0.1, 5);
		UTIL_MakeBloodAndBulletHoles(id);
	}
	else if(g_balrog1sec[id]){
		emit_sound(id, CHAN_WEAPON, g_shootsound2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 3);
		set_pdata_float(id, 83, 91/30.0, 5);
		UTIL_Explode(id);
		g_balrog1sec[id] = false
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_DEAGLE && g_hasbalrog1[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_DEAGLE && g_hasbalrog1[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(!g_balrog1sec[id]){
				g_balrog1sec[id] = true
				set_weapon_animation(id, 6);
				set_pdata_float(id, 83, 61/30.0, 5);
			}
			else{
				g_balrog1sec[id] = false
				set_weapon_animation(id, 7);
				set_pdata_float(id, 83, 39/30.0, 5);
			}
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasbalrog1[id]){
		static iclipex = 10
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_DEAGLE);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_DEAGLE, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasbalrog1[id] && !g_balrog1sec[id]){
		set_weapon_animation(id, 4);
		set_pdata_float(id, 46, 68/30.0, 4);
		set_pdata_float(id, 47, 68/30.0, 4);
		set_pdata_float(id, 48, 68/30.0, 4);
		set_pdata_float(id, 83, 68/30.0, 5);
	}
	else if(g_balrog1sec[id]){
		set_weapon_animation(id, 8);
		set_pdata_float(id, 46, 90/30.0, 4);
		set_pdata_float(id, 47, 90/30.0, 4);
		set_pdata_float(id, 48, 90/30.0, 4);
		set_pdata_float(id, 83, 90/30.0, 5);
		g_balrog1sec[id] = false
	}
}

public UTIL_Explode(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
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
		
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fStart[0])
	engfunc(EngFunc_WriteCoord, fStart[1])
	engfunc(EngFunc_WriteCoord, fStart[2])
	write_short(g_explode)
	write_byte(8)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, get_pcvar_float(cvar_balrog1sec_radius))) != 0){
		if(!is_user_alive(victim) || !zp_get_user_zombie(victim)){
			continue
		}
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHam(Ham_TakeDamage, victim, 0, id, get_pcvar_float(cvar_balrog1sec_damage), DMG_BURN);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(victim) <= 0){
			SendDeathMsg(id, victim);
		}
	}
}

public UTIL_MakeBloodAndBulletHoles(id){
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

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 12345)
	{
		g_hasbalrog1[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_deagle.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_deagle", entity);
	
	if(g_hasbalrog1[owner] && pev_valid(wpn))
	{
		g_hasbalrog1[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 12345);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_DEAGLE && g_hasbalrog1[attacker] && !g_balrog1sec[attacker])
	{
		SetHamParamFloat(4, damage + 20);
	}
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock SendDeathMsg(attacker, victim){ // Sends death message
	message_begin(MSG_BROADCAST, g_death)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("deagle") // killer's weapon
	message_end()
}

stock UTIL_WeaponList(id, const bool: bEnabled)
{
	message_begin(MSG_ONE, msgid_weaponlist, _, id);
	write_string(bEnabled ? "bakoweapon_balrog1" : "weapon_deagle");
	write_byte(8);
	write_byte(35);
	write_byte(-1);
	write_byte(-1);
	write_byte(1);
	write_byte(1);
	write_byte(26);
	write_byte(0);
	message_end();
}
