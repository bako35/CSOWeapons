#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <zombieplague>

#define VERSION "1.0"
#define SECONDARYATTACK_DELAY 0.1

new g_hasbglock[33];
new msgid_weaponlist;
new blood_spr[2];
new bglock18c;

new const g_vmodel[] = "models/v_bglock18.mdl";
new const g_pmodel[] = "models/p_bglock18.mdl";
new const g_wmodel[] = "models/w_bglock18.mdl";
new const wep_glock18 = ((1<<CSW_GLOCK18));
new const gunshut_decals[] = { 41, 42, 43, 44, 45 }

public plugin_init(){
	register_plugin("[ZP] Extra: Battle Glock 18C", VERSION, "bako35");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_glock18", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_glock18", "fw_WeaponSecondaryAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	register_clcmd("bakoweapon_bglock18", "HookWeapon");
	msgid_weaponlist = get_user_msgid("WeaponList");
	bglock18c = zp_register_extra_item("Battle Glock 18C", 0, ZP_TEAM_HUMAN);
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_glock18");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasbglock[id] = false
}

public client_disconnect(id){
	g_hasbglock[id] = false
}

public death_player(id){
	g_hasbglock[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_generic("sprites/640hud94.spr");
	precache_generic("sprites/bakoweapon_bglock18.txt");
}

public zp_extra_item_selected(id, itemid){
	if(itemid == bglock18c){
		give_bglock(id)
	}
}

public give_bglock(id){
	if(is_user_alive(id) && !g_hasbglock[id]){
		if(user_has_weapon(id, CSW_GLOCK18)){
			drop_weapon(id);
		}
		g_hasbglock[id] = true
		give_item(id, "weapon_glock18");
		cs_set_user_bpammo(id, CSW_GLOCK18, 200);
		UTIL_WeaponList(id, true);
		replace_models(id);
	}
}

public replace_models(id){
	new bglock18 = read_data(2);
	if(g_hasbglock[id] && bglock18 == CSW_GLOCK18){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++){
		if(wep_glock18 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock UTIL_WeaponList(id, const bool: bEnabled)
{
	message_begin(MSG_ONE, msgid_weaponlist, _, id);
	write_string(bEnabled ? "bakoweapon_bglock18" : "weapon_glock18");
	write_byte(10);
	write_byte(bEnabled ? 200 : 120);
	write_byte(-1);
	write_byte(-1);
	write_byte(1);
	write_byte(2);
	write_byte(17);
	write_byte(0);
	message_end();
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_glock18.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_glock18", entity);
	
	if(g_hasbglock[owner] && pev_valid(wpn))
	{
		g_hasbglock[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 43556);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 43556)
	{
		g_hasbglock[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_WeaponSecondaryAttack(Ent){
	new wid
	wid = get_pdata_cbase(Ent, 41, 4)
	if(cs_get_weapon_ammo(Ent) <= 0){
		return HAM_SUPERCEDE
	}
	if(get_pdata_float(wid, 83, 5) > 0.0){
		return HAM_SUPERCEDE
	}
	if(g_hasbglock[wid]){
		ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent);
		Weapon_SecondaryAttack(wid);
		//set_pdata_float(wid, 83, get_pdata_float(wid, 83, 5) + SECONDARYATTACK_DELAY, 5);
		set_pdata_float(wid, 83, SECONDARYATTACK_DELAY, 5);
		set_pdata_int(Ent, 64, 0, 4);
		return HAM_SUPERCEDE
	}
	else{
		return HAM_IGNORED
	}
}

public Weapon_SecondaryAttack(id){
	set_shoot_anim(id, 5);
	emit_sound(id, CHAN_WEAPON, "weapons/glock18-2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	Eject_Shell(id, engfunc(EngFunc_PrecacheModel, "models/pshell.mdl"), SECONDARYATTACK_DELAY);
	UTIL_MakeBloodAndBulletHoles(id);
}

stock set_shoot_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
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

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GLOCK18 && g_hasbglock[attacker])
	{
		SetHamParamFloat(4, damage + 10);
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
