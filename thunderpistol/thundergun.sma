#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

new g_hasthundergun[33];
new g_weaponmode[33];
new g_ammox[33];
new g_thundergunammo[33];
new blood_spr[2];
new g_exp[2];
new g_death;
new cvar_damage;
new cvar_radius_damage;
new const gunshut_decals[] = {41, 42, 43, 44, 45}
new const g_vmodel[] = "models/v_thunderpistol.mdl"
new const g_vmodel2[] = "models/v_thunderpistol_2.mdl"
new const g_pmodel[] = "models/p_thunderpistol.mdl"
new const g_wmodel[] = "models/w_all_models.mdl"

public plugin_init(){
	register_plugin("Thunder Ghost Walker", "1.0", "bako35");
	register_clcmd("gun", "give_thundergun");
	register_clcmd("bakoweapon_thunderpistol", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Item_PostFrame, "weapon_p228", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p228", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_Reload, "weapon_p228", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_p228", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_p228", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
	g_death = get_user_msgid("DeathMsg");
	cvar_damage = register_cvar("thunderghost_damage", "50.0");
	cvar_radius_damage = register_cvar("thunderghost_radius_damage", "5.0");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_vmodel2);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/thundergun_2.wav");
	precache_sound("weapons/thundergun_clipin.wav");
	precache_sound("weapons/thundergun_clipout.wav");
	precache_sound("weapons/thundergun_draw.wav");
	precache_sound("weapons/thundergun_exp.wav");
	precache_sound("weapons/thundergun_exp2.wav");
	precache_sound("weapons/thundergun_idle2_1.wav");
	precache_sound("weapons/thundergun_idle2_3.wav");
	precache_sound("weapons/thundergun-1.wav");
	precache_sound("weapons/thundergun-1-1.wav");
	precache_generic("sprites/bakoweapon_thunderpistol.txt");
	precache_generic("sprites/640hud186.spr");
	precache_generic("sprites/cso/640hud7.spr");
	precache_generic("sprites/cso/640hud14.spr");
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");
	g_exp[0] = precache_model("sprites/ef_thunderpistol_explosion_fx.spr");
	g_exp[1] = precache_model("sprites/ef_thunderpistol_explosionb_fx.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_p228");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasthundergun[id] = false
	g_weaponmode[id] = 1
	g_ammox[id] = 0
	UTIL_WeaponList(id, false);
}

public client_disconnect(id){
	g_hasthundergun[id] = false
	g_weaponmode[id] = 1
	g_ammox[id] = 0
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_hasthundergun[read_data(2)] = false
	g_weaponmode[read_data(2)] = 1
	g_ammox[read_data(2)] = 0
	set_sec_ammo(read_data(2), g_ammox[read_data(2)]);
	UTIL_WeaponList(read_data(2), false);
}

public fw_Spawn(id){
	if(g_hasthundergun[id]){
		if(g_weaponmode[id] == 2){
			g_weaponmode[id] = 1
			remove_task(9000);
			set_user_rendering(id, kRenderFxNone, 255,255,255, kRenderTransAlpha, 255);
			set_pev(id, pev_viewmodel2, g_vmodel);
			emit_sound(id, CHAN_ITEM, "weapons/thundergun_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		g_ammox[id] = 100
		set_sec_ammo(id, g_ammox[id]);
	}
}

public give_thundergun(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_P228)){
			drop_weapon(id);
		}
		g_hasthundergun[id] = true
		g_weaponmode[id] = 1
		g_ammox[id] = 100
		set_sec_ammo(id, g_ammox[id]);
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_p228")
		cs_set_weapon_ammo(wpnid, 1);
		cs_set_user_bpammo(id, CSW_P228, 50);
		replace_models(id);
	}
}

public replace_models(id){
	new thundergun = read_data(2);
	if(g_hasthundergun[id] && thundergun == CSW_P228){
		if(g_weaponmode[id] == 1){
			set_pev(id, pev_viewmodel2, g_vmodel);
		}
		else if(g_weaponmode[id] == 2){
			set_pev(id, pev_viewmodel2, g_vmodel2);
		}
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_P228) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	static vecVelocity[3]
	id = get_pdata_cbase(weapon_entity, 41, 5);
	g_thundergunammo[id] = cs_get_weapon_ammo(weapon_entity)
	if(!g_hasthundergun[id]){
		return HAM_IGNORED
	}
	if(!g_thundergunammo[id]){
		ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE
	}
	UTIL_MakeBloodAndBulletHoles(id);
	if(g_weaponmode[id] == 1){
		set_weapon_animation(id, 1);
		set_pdata_float(id, 83, 23/30.0, 5);
		emit_sound(id, CHAN_WEAPON, "weapons/thundergun-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_Explode_1(id);
	}
	else if(g_weaponmode[id] == 2){
		remove_task(9000);
		g_weaponmode[id] = 1
		set_weapon_animation(id, 2);
		set_pdata_float(id, 83, 23/30.0, 5);
		emit_sound(id, CHAN_WEAPON, "weapons/thundergun-1-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_Explode_2(id);
		emit_sound(id, CHAN_ITEM, "weapons/thundergun_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_user_rendering(id, kRenderFxNone, 255,255,255, kRenderTransAlpha, 255);
	}
	set_pdata_int(weapon_entity, 51, g_thundergunammo[id] - 1, 4);
	return HAM_SUPERCEDE
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasthundergun[id]){
		set_weapon_animation(id, 3);
		set_pdata_float(id, 46, 71/30.0, 4);
		set_pdata_float(id, 47, 71/30.0, 4);
		set_pdata_float(id, 48, 71/30.0, 4);
		set_pdata_float(id, 83, 71/30.0, 5);
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasthundergun[id]){
		static iclipex = 1
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_P228);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_P228, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_P228 && g_hasthundergun[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_P228 && g_hasthundergun[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1 && g_ammox[id] > 0){
				new data[1]
				data[0] = id
				set_user_rendering(id, kRenderFxNone, 0,0,0, kRenderTransAlpha, 0);
				set_pev(id, pev_viewmodel2, g_vmodel2);
				set_task(0.1, "sec_ammo", 9000, data, 1, "b");
				emit_sound(id, CHAN_ITEM, "weapons/thundergun_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				g_weaponmode[id] = 2
			}
			else if(g_weaponmode[id] == 2){
				set_user_rendering(id, kRenderFxNone, 255,255,255, kRenderTransAlpha, 255);
				set_pev(id, pev_viewmodel2, g_vmodel);
				emit_sound(id, CHAN_ITEM, "weapons/thundergun_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				remove_task(9000);
				g_weaponmode[id] = 1
			}
			else if(g_weaponmode[id] == 1 && g_ammox[id] <= 0){
				emit_sound(id, CHAN_VOICE, "common/wpn_denyselect.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
		}
	}
}

public sec_ammo(data[]){
	new id = data[0]
	g_ammox[id] -= 1
	set_sec_ammo(id, g_ammox[id]);
	if(g_ammox[id] <= 0 && g_weaponmode[id] == 2){
		remove_task(9000);
		g_weaponmode[id] = 1
		g_ammox[id] = 0
		set_sec_ammo(id, g_ammox[id]);
		set_user_rendering(id, kRenderFxNone, 255,255,255, kRenderTransAlpha, 255);
		set_pev(id, pev_viewmodel2, g_vmodel);
		emit_sound(id, CHAN_ITEM, "weapons/thundergun_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

public UTIL_Explode_1(id){
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
	write_short(g_exp[0])
	write_byte(8)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS)
	message_end()
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, 100.0)) != 0){
		if(!is_user_alive(victim) || get_user_team(id) == get_user_team(victim)){
			continue
		}
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHamB(Ham_TakeDamage, victim, id, id, get_pcvar_float(cvar_radius_damage), DMG_SHOCK|DMG_NEVERGIB);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(victim) <= 0){
			SendDeathMsg(id, victim, 0, "p228");
		}
	}
}

public UTIL_Explode_2(id){
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
	write_short(g_exp[1])
	write_byte(8)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES|TE_EXPLFLAG_NODLIGHTS)
	message_end()
	
	new victim
	victim = -1
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, fStart, 100.0)) != 0){
		if(!is_user_alive(victim) || get_user_team(id) == get_user_team(victim)){
			continue
		}
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHamB(Ham_TakeDamage, victim, 0, id, get_pcvar_float(cvar_radius_damage) * 3.0, DMG_SHOCK|DMG_NEVERGIB);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(victim) <= 0){
			SendDeathMsg(id, victim, 1, "p228");
		}
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasthundergun[id]){
		set_weapon_animation(id, 4);
		set_pdata_float(id, 83, 39/30.0, 5);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 1234567)
	{
		g_hasthundergun[id] = true;
		g_weaponmode[id] = 1
		g_ammox[id] = pev(weapon_entity, pev_iuser4)
		set_sec_ammo(id, g_ammox[id]);
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_p228.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_p228", entity);
	
	if(g_hasthundergun[owner] && pev_valid(wpn))
	{
		g_hasthundergun[owner] = false;
		if(g_weaponmode[owner] == 2){
			g_weaponmode[owner] = 1
			remove_task(9000);
			set_user_rendering(owner, kRenderFxNone, 255,255,255, kRenderTransAlpha, 255);
		}
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 1234567);
		set_pev(wpn, pev_iuser4, g_ammox[owner]);
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

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_thunderpistol" : "weapon_p228");
	write_byte(9)
	write_byte(bEnabled ? 50 : 52)
	write_byte(bEnabled ? 1 : -1)
	write_byte(bEnabled ? 100 : -1)
	write_byte(1)
	write_byte(3)
	write_byte(1)
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

stock UTIL_MakeBloodAndBulletHoles(id){
   new aimOrigin[3], target, body
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

      new Float:dmg = get_pcvar_float(cvar_damage)

      new hitGroup = get_tr2(hTrace, TR_iHitgroup);

      switch (hitGroup){
         case HIT_HEAD: {dmg *= 3.0;}
         case HIT_LEFTARM: {dmg *= 1.0;}
         case HIT_RIGHTARM: {dmg *= 1.0;}
         case HIT_LEFTLEG: {dmg *= 1.0;}
         case HIT_RIGHTLEG: {dmg *= 1.0;}
      }
      if(is_user_connected(hitEnt) && cs_get_user_team(id) != cs_get_user_team(hitEnt)){
      	if(g_weaponmode[id] == 1){
		ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg, DMG_BULLET|DMG_SHOCK|DMG_NEVERGIB);
		ExecuteHam(Ham_TraceBleed, hitEnt, dmg, VecDir, hTrace, DMG_BULLET|DMG_SHOCK|DMG_NEVERGIB);
	}
	else if(g_weaponmode[id] == 2){
		set_msg_block(g_death, BLOCK_SET);
		ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg *= 3.0, DMG_BULLET|DMG_SHOCK|DMG_NEVERGIB);
		ExecuteHam(Ham_TraceBleed, hitEnt, dmg *= 3.0, VecDir, hTrace, DMG_BULLET|DMG_SHOCK|DMG_NEVERGIB);
		set_msg_block(g_death, BLOCK_NOT);
		if(get_user_health(hitEnt) <= 0){
			SendDeathMsg(id, hitEnt, 1, "p228");
		}
	}
         make_blood(VecEnd, dmg, hitEnt);
      }
	}
   }
   else if(!is_user_connected(target))
   {
      if(target)
      {
         message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
         write_byte(TE_DECAL)
         write_coord(aimOrigin[0])
         write_coord(aimOrigin[1])
         write_coord(aimOrigin[2])
         write_byte(gunshut_decals[random_num(0, sizeof gunshut_decals -1)])
         write_short(target)
         message_end()
      }
      else
      {
         message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
         write_byte(TE_WORLDDECAL)
         write_coord(aimOrigin[0])
         write_coord(aimOrigin[1])
         write_coord(aimOrigin[2])
         write_byte(gunshut_decals[random_num (0, sizeof gunshut_decals -1)])
         message_end()
      }
      
      message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
      write_byte(TE_GUNSHOTDECAL)
      write_coord(aimOrigin[0])
      write_coord(aimOrigin[1])
      write_coord(aimOrigin[2])
      write_short(id)
      write_byte(gunshut_decals[random_num (0, sizeof gunshut_decals -1)])
      message_end()
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
