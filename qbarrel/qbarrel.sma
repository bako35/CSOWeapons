#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

new g_hasqbarrel[33];
new g_qbarrelammo[33];
new g_secondaryfire[33];
new const g_vmodel[] = "models/v_qbarrel.mdl"
new const g_pmodel[] = "models/p_qbarrel.mdl"
new const g_wmodel[] = "models/w_qbarrel.mdl"

public plugin_init() {
	register_plugin("Q-Barrel", "1.0", "bako35");
	register_clcmd("gun", "give_qbarrel");
	register_clcmd("bakoweapon_qbarrel", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Item_PostFrame, "weapon_xm1014", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_xm1014", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_xm1014", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_xm1014", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_xm1014", "fw_AddToPlayer", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/qbarrel_clipin1.wav");
	precache_sound("weapons/qbarrel_clipin2.wav");
	precache_sound("weapons/qbarrel_clipout1.wav");
	precache_sound("weapons/qbarrel_draw.wav");
	precache_sound("weapons/qbarrel-1.wav");
	precache_generic("sprites/cso/640hud7.spr");
	precache_generic("sprites/640hud60.spr");
	precache_generic("sprites/bakoweapon_qbarrel.txt");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_xm1014");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasqbarrel[id] = false
	g_secondaryfire[id] = false
}

public client_disconnect(id){
	g_hasqbarrel[id] = false
	g_secondaryfire[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasqbarrel[read_data(2)] = false
	g_secondaryfire[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public give_qbarrel(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_XM1014)){
			drop_weapon(id);
		}
		g_hasqbarrel[id] = true
		g_secondaryfire[id] = false
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_xm1014");
		cs_set_weapon_ammo(wpnid, 4);
		cs_set_user_bpammo(id, CSW_XM1014, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new qbarrel = read_data(2);
	if(g_hasqbarrel[id] && qbarrel == CSW_XM1014){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_XM1014) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}


public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_XM1014 && g_hasqbarrel[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasqbarrel[id]){
		new g_qbarrelammo2
		g_qbarrelammo2 = cs_get_user_bpammo(id, CSW_XM1014);
		if(g_qbarrelammo2 <= 0){
			return HAM_IGNORED
		}
		set_pdata_int(weapon_entity, 55, 0, 4);
		set_pdata_float(weapon_entity, 46, 91/30.0, 4);
		set_pdata_float(weapon_entity, 47, 91/30.0, 4);
		set_pdata_float(weapon_entity, 48, 91/30.0, 4);
		set_pdata_float(id, 83, 91/30.0, 5);
		set_pdata_int(weapon_entity, 54, 1, 4);
		set_weapon_animation(id, 3);
		g_secondaryfire[id] = false
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hasqbarrel[id]){
		g_qbarrelammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasqbarrel[id] && g_qbarrelammo[id]){
		emit_sound(id, CHAN_WEAPON, "weapons/qbarrel-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_float(id, 83, 0.2, 5);
		if(g_secondaryfire[id]){
			set_weapon_animation(id, 2);
			g_secondaryfire[id] = false
		}
		else if(!g_secondaryfire[id]){
			set_weapon_animation(id, 1);
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasqbarrel[id]){
		static iclipex = 4
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_XM1014);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_XM1014, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasqbarrel[id]){
		set_weapon_animation(id, 4);
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_XM1014 && g_hasqbarrel[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			static weapon_entity
			weapon_entity = fm_get_user_weapon_entity(id, CSW_XM1014);
			if(cs_get_weapon_ammo(weapon_entity) == 4){
				g_secondaryfire[id] = true
				ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_entity);
				cs_set_weapon_ammo(weapon_entity, 0);
			}
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage){
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_XM1014 && g_hasqbarrel[attacker] && g_secondaryfire[attacker]){
		SetHamParamFloat(4, damage + 10 * 4);
	}
	else if(!g_secondaryfire[attacker]){
		SetHamParamFloat(4, damage + 10);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 121212122)
	{
		g_hasqbarrel[id] = true;
		g_secondaryfire[id] = false
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_xm1014.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_xm1014", entity);
	
	if(g_hasqbarrel[owner] && pev_valid(wpn))
	{
		g_secondaryfire[owner] = false;
		g_hasqbarrel[owner] = true
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 121212122);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
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
	write_string(bEnabled ? "bakoweapon_qbarrel" : "weapon_xm1014");
	write_byte(5)
	write_byte(32)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(12)
	write_byte(5)
	write_byte(0)
	message_end();
}
