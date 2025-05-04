#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_haslaserfist[33];
new g_laserfistammo[33];
new g_weaponmode[33];
new g_secshoot[33];
new g_exp;
new g_trail;
new inflaserfist;
new const g_vmodel[] = "models/v_laserfist.mdl"
new const g_vmodel2[] = "models/v_laserfist2.mdl"
new const g_pmodel[] = "models/p_laserfist.mdl"
new const g_wmodel[] = "models/w_laserfist.mdl"

public plugin_init() {
	register_plugin("Infinity Laser Fist", "1.0", "bako35");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_tmp", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tmp", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tmp", "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_tmp", "fw_ReloadWeapon", 1);
	inflaserfist = zp_register_extra_item("Infinity Laser Fist", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_vmodel2);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/laserfist_b1.wav");
	precache_sound("weapons/laserfist_clipin1.wav");
	precache_sound("weapons/laserfist_clipin2.wav");
	precache_sound("weapons/laserfist_clipout.wav");
	precache_sound("weapons/laserfist_draw1.wav");
	precache_sound("weapons/laserfist_idle.wav");
	precache_sound("weapons/laserfist_shoota_empty_end.wav");
	precache_sound("weapons/laserfist_shoota_empty_loop.wav");
	precache_sound("weapons/laserfist_shoota-1.wav");
	precache_sound("weapons/laserfist_shootb_exp.wav");
	precache_sound("weapons/laserfist_shootb_loop.wav");
	precache_sound("weapons/laserfist_shootb_ready.wav");
	precache_sound("weapons/laserfist_shootb_shoot.wav");
	precache_sound("weapons/laserfist_shootb-1.wav");
	g_exp = precache_model("sprites/laserfist/ef_laserfist_laser_explosion.spr");
	g_trail = precache_model("sprites/laserfist/ef_laserfist_laserbeam.spr");
	
}

public client_connect(id){
	g_haslaserfist[id] = false
	g_secshoot[id] = 0
	g_weaponmode[id] = 1
}

public client_disconnect(id){
	g_haslaserfist[id] = false
	g_secshoot[id] = 0
	g_weaponmode[id] = 1
}

public death_player(){
	g_haslaserfist[read_data(2)] = false
	g_secshoot[read_data(2)] = 0
	g_weaponmode[read_data(2)] = 1
}

public zp_extra_item_selected(id, itemid){
	if(itemid == inflaserfist){
		give_laserfist(id);
	}
}

public give_laserfist(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_TMP)){
			drop_weapon(id);
		}
		g_haslaserfist[id] = true
		g_secshoot[id] = 0
		g_weaponmode[id] = 1
		new wpnid = give_item(id, "weapon_tmp")
		cs_set_weapon_ammo(wpnid, 100);
		cs_set_user_bpammo(id, CSW_TMP, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new laserfist = read_data(2);
	if(g_haslaserfist[id] && laserfist == CSW_TMP){
		if(g_secshoot[id] != 20){
			set_pev(id, pev_viewmodel2, g_vmodel);
		}
		else if(g_secshoot[id] == 20){
			set_pev(id, pev_viewmodel2, g_vmodel2);
		}
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_TMP) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_haslaserfist[id]){
		static iclipex = 100
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_TMP);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_TMP, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_TMP && g_haslaserfist[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_haslaserfist[id] && g_weaponmode[id] == 1){
		g_laserfistammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
	else if(g_weaponmode[id] == 2){
		g_laserfistammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_haslaserfist[id] && g_laserfistammo[id] && g_weaponmode[id] == 1){
		g_secshoot[id] += 1
		if(g_secshoot[id] >= 20){
			set_pev(id, pev_viewmodel2, g_vmodel2);
			g_secshoot[id] = 20
		}
		emit_sound(id, CHAN_WEAPON, "weapons/laserfist_shoota-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 3);
		//UTIL_MakeBloodAndBulletHoles(id);
	}
	else if(g_weaponmode[id] == 2 && g_secshoot[id] == 20){
		set_pev(id, pev_viewmodel2, g_vmodel);
		g_weaponmode[id] = 1
		g_secshoot[id] = 0
		emit_sound(id, CHAN_WEAPON, "weapons/laserfist_shootb-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_weapon_animation(id, 7);
		set_pdata_float(id, 83, 50/30.0, 5);
		UTIL_Explode(id);
	}
}

public UTIL_Explode(id){
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3], fPlayer[3];
	pev(id, pev_origin, fStart);
	pev(id, pev_origin, fPlayer);
		
	velocity_by_aim(id, 64, fVel);
	fStart[0] = float(aimOrigin[0]);
	fStart[1] = float(aimOrigin[1]);
	fStart[2] = float(aimOrigin[2]);
		
	new res;
	engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res);
	get_tr2(res, TR_vecEndPos, fRes);
		
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fStart[0])
	engfunc(EngFunc_WriteCoord, fStart[1])
	engfunc(EngFunc_WriteCoord, fStart[2])
	write_short(g_exp)
	write_byte(8)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,fPlayer[0]);
	engfunc(EngFunc_WriteCoord,fPlayer[1]);
	engfunc(EngFunc_WriteCoord,fPlayer[2]);
	engfunc(EngFunc_WriteCoord,fStart[0]); //Random
	engfunc(EngFunc_WriteCoord,fStart[1]); //Random
	engfunc(EngFunc_WriteCoord,fStart[2]); //Random
	write_short(g_trail);
	write_byte(0);
	write_byte(100);
	write_byte(10);	//Life
	write_byte(100);//Width
	write_byte(0);	//wave
	write_byte(255); // r
	write_byte(255); // g
	write_byte(255); // b
	write_byte(255); // alpha
	write_byte(255); // speed (?)
	message_end();
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, 30.0)) != 0){
		if(!is_user_alive(victim) || !zp_get_user_zombie(victim)){
			continue
		}
		ExecuteHamB(Ham_TakeDamage, victim, id, id, 200.0, DMG_ENERGYBEAM);
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_haslaserfist[id] && g_weaponmode[id] == 1){
		set_weapon_animation(id, 8);
		set_pdata_float(id, 46, 81/30.0, 4);
		set_pdata_float(id, 47, 81/30.0, 4);
		set_pdata_float(id, 48, 81/30.0, 4);
		set_pdata_float(id, 83, 81/30.0, 5);
	}
}

public fw_CmdStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_haslaserfist[id] && get_user_weapon(id) == CSW_TMP){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 3 && g_weaponmode[id] == 1){
			set_weapon_animation(id, 4);
		}
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1 && g_secshoot[id] == 20){
				set_weapon_animation(id, 5);
				set_pdata_float(id, 83, 39/30.0, 5);
				g_weaponmode[id] = 2
			}
			else if(g_secshoot[id] != 20 || g_weaponmode[id] == 2){
				emit_sound(id, CHAN_VOICE, "common/wpn_denyselect.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		}
	}
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
