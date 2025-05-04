#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <xs>

new g_hascyclone[33];
new g_cycloneammo[33];
new blood_spr[2];
new g_trail;
new cvar_damage;
new const g_vmodel[] = "models/v_sfpistol.mdl"
new const g_pmodel[] = "models/p_sfpistol.mdl"
new const g_wmodel[] = "models/w_sfpistol.mdl"

public plugin_init() {
	register_plugin("Cyclone", "1.0", "bako35");
	register_clcmd("bakoweapon_sfpistol", "HookWeapon");
	register_clcmd("gun", "give_cyclone");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_glock18", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_glock18", "fw_SecondaryAttack");
	RegisterHam(Ham_Item_PostFrame, "weapon_glock18", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_glock18", "fw_WeaponIdle", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_glock18", "fw_DeployPost", 1);
	RegisterHam(Ham_Weapon_Reload, "weapon_glock18", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_glock18", "fw_AddToPlayer", 1);
	cvar_damage = register_cvar("cyclone_damage", "8.0");
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound("weapons/sfpistol_clipin.wav");
	precache_sound("weapons/sfpistol_clipout.wav");
	precache_sound("weapons/sfpistol_draw.wav");
	precache_sound("weapons/sfpistol_idle.wav");
	precache_sound("weapons/sfpistol_shoot_end.wav");
	precache_sound("weapons/sfpistol_shoot_start.wav");
	precache_sound("weapons/sfpistol_shoot1.wav");
	precache_generic("sprites/640hud12.spr");
	precache_generic("sprites/640hud104.spr");
	precache_generic("sprites/bakoweapon_sfpistol.txt");
	g_trail = precache_model("sprites/laserbeam.spr");
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_glock18");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hascyclone[id] = false
}

public client_disconnect(id){
	g_hascyclone[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(){
	g_hascyclone[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public give_cyclone(id){
	if(is_user_alive(id)){
		if(user_has_weapon(id, CSW_GLOCK18)){
			drop_weapon(id);
		}
		g_hascyclone[id] = true
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_glock18")
		cs_set_weapon_ammo(wpnid, 50);
		cs_set_user_bpammo(id, CSW_GLOCK18, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new cyclone = read_data(2);
	if(g_hascyclone[id] && cyclone == CSW_GLOCK18){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_GLOCK18) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_GLOCK18 && g_hascyclone[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_PrimaryAttack(weapon_entity){
	new id
	new Float:fCurTime
	new Float:fSound
	id = get_pdata_cbase(weapon_entity, 41, 5);
	global_get(glb_time, fCurTime);
	pev(weapon_entity, pev_fuser1, fSound);
	g_cycloneammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_hascyclone[id]){
		return HAM_IGNORED
	}
	if(!g_cycloneammo[id]){
		ExecuteHamB(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
		return HAM_SUPERCEDE
	}
	set_pdata_float(id, 83, 0.1, 5);
	set_pdata_float(weapon_entity, 46, 0.1, 4);
	set_pdata_float(weapon_entity, 48, 0.6, 4);
	set_weapon_animation(id, 1);
	if(fSound < fCurTime){
		emit_sound(id, CHAN_WEAPON, "weapons/sfpistol_shoot1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pev(weapon_entity, pev_fuser1, fCurTime + 1.0);
	}
	set_pdata_int(weapon_entity, 51, g_cycloneammo[id] - 1, 4);
	UTIL_MakeBloodAndBulletHoles(id);
	laser(id);
	return HAM_SUPERCEDE
}

public laser(id){
	static Float:startOrigin[3];
	static Float:endOrigin[3];
	new aimOrigin[3];
	pev(id, pev_origin, startOrigin);
	pev(id, pev_origin, endOrigin);
	get_user_origin(id, aimOrigin, 3);
	
	endOrigin[0] = float(aimOrigin[0]);
	endOrigin[1] = float(aimOrigin[1]);
	endOrigin[2] = float(aimOrigin[2]);
	
	engfunc(EngFunc_TraceLine, startOrigin, endOrigin, DONT_IGNORE_MONSTERS, id, 0);
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,startOrigin[0]);
	engfunc(EngFunc_WriteCoord,startOrigin[1]);
	engfunc(EngFunc_WriteCoord,startOrigin[2]);
	engfunc(EngFunc_WriteCoord,endOrigin[0]); //Random
	engfunc(EngFunc_WriteCoord,endOrigin[1]); //Random
	engfunc(EngFunc_WriteCoord,endOrigin[2]); //Random
	write_short(g_trail);
	write_byte(0);
	write_byte(0);
	write_byte(1);//Life
	write_byte(20);	//Width
	write_byte(0);	//wave
	write_byte(0); // r
	write_byte(255); // g
	write_byte(0); // b
	write_byte(200);
	write_byte(0);
	message_end();
}

public fw_SecondaryAttack(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 5);
	if(g_hascyclone[id]){
		return HAM_SUPERCEDE
	}
	return HAM_IGNORED
}

public fw_CmdStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_hascyclone[id] && get_user_weapon(id) == CSW_GLOCK18){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 1){
			set_weapon_animation(id, 2);
			emit_sound(id, CHAN_WEAPON, "weapons/sfpistol_shoot_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hascyclone[id]){
		static iclipex = 50
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_GLOCK18);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_GLOCK18, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_WeaponIdle(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!is_user_alive(id) || !g_hascyclone[id] || get_user_weapon(id) != CSW_GLOCK18){
		return HAM_IGNORED
	}
	if(g_hascyclone[id] && get_pdata_float(weapon_entity, 48, 4) <= 0.2){
		set_weapon_animation(id, 0)
		set_pdata_float(weapon_entity, 48, 101/30.0, 4);
	}
}

public fw_DeployPost(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!g_hascyclone[id]){
		return HAM_IGNORED
	}
	set_weapon_animation(id, 4);
	set_pdata_float(id, 83, 40/30.0, 5);
	return HAM_SUPERCEDE
}

public fw_ReloadWeapon(weapon_entity){
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!g_hascyclone[id]){
		return HAM_IGNORED
	}
	set_weapon_animation(id, 3);
	set_pdata_float(id, 46, 67/30.0, 4);
	set_pdata_float(id, 47, 67/30.0, 4);
	set_pdata_float(id, 48, 67/30.0, 4);
	set_pdata_float(id, 83, 67/30.0, 5);
	return HAM_SUPERCEDE
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 88888)
	{
		g_hascyclone[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_glock18.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_glock18", entity);
	
	if(g_hascyclone[owner] && pev_valid(wpn)){
		g_hascyclone[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 88888);
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock set_weapon_animation(id, anim){
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
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
      	ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg, DMG_SHOCK|DMG_NEVERGIB);
	ExecuteHam(Ham_TraceBleed, hitEnt, dmg, VecDir, hTrace, DMG_SHOCK|DMG_NEVERGIB);
	make_blood(VecEnd, dmg, hitEnt);
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
	write_string(bEnabled ? "bakoweapon_sfpistol" : "weapon_glock18");
	write_byte(10)
	write_byte(120)
	write_byte(-1)
	write_byte(-1)
	write_byte(1)
	write_byte(2)
	write_byte(17)
	write_byte(0)
	message_end();
}
