#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

new g_hasdualinf[33];
new g_dualinfammo[33];
new blood_spr[2];
new msgif_weaponlist;
new g_secondaryfire[33];
new cvar_damage;
new const g_vmodel[] = "models/v_dualinf.mdl"
new const g_pmodel[] = "models/p_dualinf.mdl"
new const g_wmodel[] = "models/w_dualinf.mdl"
new const g_shootsound[] = "weapons/dualinf_fire.wav"
new const gunshut_decals[] = {41, 42, 43, 44, 45}

public plugin_init(){
	register_plugin("Dual Infinity Final", "1.0", "bako35");
	register_clcmd("gun", "give_dualinf");
	register_clcmd("bakoweapon_infinityex2", "HookWeapon");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_event("DeathMsg", "death_player", "a");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_Reload, "weapon_elite", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_elite", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_elite", "fw_AddToPlayer", 1);
	msgif_weaponlist = get_user_msgid("WeaponList");
	cvar_damage = register_cvar("dualinf_damage", "20.0");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound("weapons/infi_clipin.wav");
	precache_sound("weapons/infi_clipon.wav");
	precache_sound("weapons/infi_clipout.wav");
	precache_sound("weapons/infi_draw.wav");
	precache_generic("sprites/640hud42.spr");
	precache_generic("sprites/640hud43.spr");
	precache_generic("sprites/bakoweapon_infinityex2.txt");
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");
	
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_elite");
}
	
public client_connect(id){
	g_hasdualinf[id] = false
	g_secondaryfire[id] = false
}

public client_disconnect(id){
	g_hasdualinf[id] = false
	g_secondaryfire[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasdualinf[read_data(2)] = false
	g_secondaryfire[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public give_dualinf(id){
	if(is_user_alive(id) && !g_hasdualinf[id]){
		if(user_has_weapon(id, CSW_ELITE)){
			drop_weapon(id);
		}
		g_hasdualinf[id] = true
		g_secondaryfire[id] = false
		new wpnid
		wpnid = give_item(id, "weapon_elite");
		cs_set_weapon_ammo(wpnid, 40);
		cs_set_user_bpammo(id, CSW_ELITE, 200);
		UTIL_WeaponList(id, true);
		replace_models(id);
	}
}

public replace_models(id){
	new dualinf = read_data(2);
	if(g_hasdualinf[id] && dualinf == CSW_ELITE){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_ELITE) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	new num
	static vecVelocity[3]
	id = get_pdata_cbase(weapon_entity, 41, 5);
	pev(id, pev_velocity, vecVelocity);
	num = random_num(1, 2)
	g_dualinfammo[id] = cs_get_weapon_ammo(weapon_entity)
	if(!g_hasdualinf[id]){
		return HAM_IGNORED
	}
	if(!g_dualinfammo[id]){
		ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE
	}
	set_pdata_float(id, 83, 0.3, 5);
	if(num == 1 && !g_secondaryfire[id]){
		set_weapon_animation(id, 4);
	}
	else if(num == 2 && !g_secondaryfire[id]){
		set_weapon_animation(id, 10);
	}
	else if(num == 1 && g_secondaryfire[id]){
		set_weapon_animation(id, 2)
	}
	else if(num == 2 && g_secondaryfire[id]){
		set_weapon_animation(id, 8)
	}
	emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_MakeBloodAndBulletHoles(id);
	// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/dlls/wpn_shared/wpn_ak47.cpp#L155
	if(xs_vec_len(vecVelocity) > 0)
		UTIL_WeaponKickBack(weapon_entity, id, 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7);
	else if(!(pev(id, pev_flags) & FL_ONGROUND))
		UTIL_WeaponKickBack(weapon_entity, id, 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5);
	else if(pev(id, pev_flags) & FL_DUCKING)
		UTIL_WeaponKickBack(weapon_entity, id, 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9);
	else
		UTIL_WeaponKickBack(weapon_entity, id, 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8);
	set_pdata_int(weapon_entity, 51, g_dualinfammo[id] - 1, 4);
	return HAM_SUPERCEDE
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_ELITE && g_hasdualinf[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
		return FMRES_HANDLED
	}
}

public fw_CmdStart(id, uc_handle){
	if(!is_user_alive(id)){
		return
	}
	static Button
	new num
	num = random_num(1, 2)
	Button = get_uc(uc_handle, UC_Buttons)
	if(Button & IN_ATTACK2 && get_user_weapon(id) == CSW_ELITE && g_hasdualinf[id]){
		static Float:Next
		Next = get_pdata_float(id, 83, 5)
		if(Next > 0.0){
			return
		}
		static ent
		g_secondaryfire[id] = true
		ent = fm_get_user_weapon_entity(id, CSW_ELITE)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent);
		set_pdata_float(id, 83, 0.1, 5);
	}
	else if(Button & IN_ATTACK && get_user_weapon(id) == CSW_ELITE && g_hasdualinf[id]){
		g_secondaryfire[id] = false
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasdualinf[id]){
		static iclipex = 40
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_ELITE);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_ELITE, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasdualinf[id]){
		set_weapon_animation(id, 14);
		set_pdata_float(id, 46, 121/25.0, 4);
		set_pdata_float(id, 47, 121/25.0, 4);
		set_pdata_float(id, 48, 121/25.0, 4);
		set_pdata_float(id, 83, 121/25.0, 5);
		g_secondaryfire[id] = false
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 23456)
	{
		g_hasdualinf[id] = true;
		g_secondaryfire[id] = false
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_elite.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_elite", entity);
	
	if(g_hasdualinf[owner] && pev_valid(wpn))
	{
		g_hasdualinf[owner] = false;
		g_secondaryfire[owner] = false
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 23456);
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

      new Float:dmg = get_pcvar_float(cvar_damage);

      new hitGroup = get_tr2(hTrace, TR_iHitgroup);

      switch (hitGroup){
         case HIT_HEAD: {dmg *= 3.0;}
         case HIT_LEFTARM: {dmg *= 1.0;}
         case HIT_RIGHTARM: {dmg *= 1.0;}
         case HIT_LEFTLEG: {dmg *= 1.0;}
         case HIT_RIGHTLEG: {dmg *= 1.0;}
      }
      if(is_user_connected(hitEnt) && cs_get_user_team(id) != cs_get_user_team(hitEnt)){
      	if(!g_secondaryfire[id]){
		ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg, DMG_BULLET|DMG_NEVERGIB);
		ExecuteHam(Ham_TraceBleed, hitEnt, dmg, VecDir, hTrace, DMG_BULLET|DMG_NEVERGIB);
	}
	else{
		ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg - 5.0, DMG_BULLET|DMG_NEVERGIB);
		ExecuteHam(Ham_TraceBleed, hitEnt, dmg - 5.0, VecDir, hTrace, DMG_BULLET|DMG_NEVERGIB);
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

stock UTIL_WeaponKickBack(const pItem, const pPlayer, Float: upBase, Float: lateralBase, const Float: upMod, const Float: lateralMod, Float: upMax, Float: lateralMax, const directionChange){ // by S3xTy
	static iDirection, iShotsFired; iShotsFired = get_pdata_int(pItem, 64, 4)
	static Float: vecPunchangle[3]; pev(pPlayer, pev_punchangle, vecPunchangle);
	if(iShotsFired != 1)
	{
		upBase += iShotsFired * upMod;
		lateralBase += iShotsFired * lateralMod;
	}
	
	upMax *= -1.0; vecPunchangle[0] -= upBase;
	if(upMax >= vecPunchangle[0])
		vecPunchangle[0] = upMax;
	
	if((iDirection = get_pdata_int(pItem, 64, 4)))
	{
		vecPunchangle[1] += lateralBase;
		if(lateralMax < vecPunchangle[1])
			vecPunchangle[1] = lateralMax;
	}
	else
	{
		lateralMax *= -1.0;
		vecPunchangle[1] -= lateralBase;
		
		if(lateralMax > vecPunchangle[1])
			vecPunchangle[1] = lateralMax;
	}
	
	if(!random_num(0, directionChange))
		set_pdata_int(pItem, 64, !iDirection, 4);
	
	set_pev(pPlayer, pev_punchangle, vecPunchangle);
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_infinityex2" : "weapon_elite");
	write_byte(10);
	write_byte(120);
	write_byte(-1);
	write_byte(-1);
	write_byte(1);
	write_byte(5);
	write_byte(10);
	write_byte(0);
	message_end();
}
