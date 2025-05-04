#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <zombieplague>

new g_hasthunderbolt[33];
new g_thunderboltammo[33];
new g_thunderboltPammo[33];
new g_zoom[33];
new Float:g_delay[33];
new g_reload[33];
new blood_spr[2];
new trail;
new g_secdeath;
new g_deathmsg;
new sfsniper;
new cvar_ammo;
new cvar_damage;
new cvar_infammo;
new const gunshut_decals[] = { 41, 42, 43, 44, 45 };
new const g_vmodel[] = "models/v_sfsniper.mdl"
new const g_pmodel[] = "models/p_sfsniper.mdl"
new const g_wmodel[] = "models/w_sfsniper.mdl"
new const g_shootsound[] = "weapons/sfsniper-1.wav" 

public plugin_init() {
	register_plugin("Thunderbolt", "1.0", "bako35");
	register_clcmd("say /gun", "give_thunderbolt");
	register_clcmd("bakoweapon_sfsniper", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_PlayerPreThink, "fw_PreThink");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_Reload, "weapon_awp", "fw_ReloadWeapon");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_awp", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_awp", "fw_SecondaryAttack");
	RegisterHam(Ham_Item_Deploy, "weapon_awp", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_awp", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Spawn, "player", "fw_Spawn", 1);
	g_deathmsg = get_user_msgid("WeaponList")
	cvar_ammo = register_cvar("thunderbolt_ammo", "30");
	cvar_damage = register_cvar("thunderbolt_damage", "150.0");
	cvar_infammo = register_cvar("thunderbolt_infinite_ammo", "1");
	sfsniper = zp_register_extra_item("Thunderbolt", 0, ZP_TEAM_HUMAN);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_shootsound);
	precache_sound("weapons/sfsniper_draw.wav");
	precache_sound("weapons/sfsniper_idle.wav");
	precache_sound("weapons/sfsniper_insight1.wav");
	precache_sound("weapons/sfsniper_zoom.wav");
	precache_generic("sprites/bakoweapon_sfsniper.txt");
	precache_generic("sprites/640hud81.spr");
	precache_generic("sprites/cso/640hud2.spr");
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");
	trail = precache_model("sprites/laserbeam.spr");
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_awp");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasthunderbolt[id] = false
	g_reload[id] = false
	g_zoom[id] = false
	UTIL_WeaponList(id, false);
}

public client_disconnect(id){
	g_hasthunderbolt[id] = false
	g_reload[id] = false
	g_zoom[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasthunderbolt[read_data(2)] = false
	g_reload[read_data(2)] = false
	g_zoom[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hasthunderbolt[id] = false
	g_reload[id] = false
	g_zoom[id] = false
	UTIL_WeaponList(id, false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == sfsniper){
		give_thunderbolt(id);
	}
}

public give_thunderbolt(id){
	if(is_user_alive(id) && !g_hasthunderbolt[id]){
		if(user_has_weapon(id, CSW_AWP)){
			drop_weapon(id);
		}
		g_hasthunderbolt[id] = true
		g_reload[id] = false
		g_thunderboltPammo[id] = get_pcvar_num(cvar_ammo)
		new wpnid = give_item(id, "weapon_awp");
		cs_set_weapon_ammo(wpnid, 1);
		replace_models(id);
		UTIL_WeaponList(id, true);
		hud(id);
	}
}

public replace_models(id){
	new thunderbolt = read_data(2);
	if(g_hasthunderbolt[id] && thunderbolt == CSW_AWP){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
		hud(id);
	}
}

public drop_weapon(id){
	new weapons[32], num
	get_user_weapons(id, weapons, num);
	for (new i = 0; i<num; i++){
		if((1<<CSW_AWP) & (1<<weapons[i])){
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname)
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_AWP && g_hasthunderbolt[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public hud(id){
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_awp", id)
	if(pev_valid(weapon_ent)){
		cs_set_weapon_ammo(weapon_ent, 1)
	}
	cs_set_user_bpammo(id, CSW_AWP, g_thunderboltPammo[id]);
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_AWP)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_thunderboltPammo[id])
	message_end()
}

public fw_PrimaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	g_thunderboltammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_hasthunderbolt[id]){
		return HAM_IGNORED;
	}
	if(!g_thunderboltPammo[id] || !g_thunderboltammo[id]){
		ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
	}
	if(g_hasthunderbolt[id] && g_thunderboltammo[id] && g_thunderboltPammo[id]){
		set_pdata_float(id, 83, 79/30.0, 5);
		set_pdata_float(weapon_entity, 46, 79/30.0, 4);
		set_weapon_animation(id, 1);
		emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_MakeBloodAndBulletHoles(id);
		laser(id);
		hud(id);
		if(g_thunderboltPammo[id] >= 1){
			if(get_pcvar_num(cvar_infammo) == 0){
				g_thunderboltPammo[id] -= 1
			}
			else if(get_pcvar_num(cvar_infammo) > 0){
				g_thunderboltPammo[id] == get_pcvar_num(cvar_ammo)
			}
		}
		if(g_zoom[id] != 0){
			new data[1]
			data[0] = id
			cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
			g_reload[id] = true
			set_task(79/30.0, "restore_zoom", .parameter=data, .len=1);
		}
	}
	return HAM_SUPERCEDE;
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
	write_short(trail);
	write_byte(0);
	write_byte(0);
	write_byte(15);	//Life
	write_byte(30);	//Width
	write_byte(0);	//wave
	write_byte(0); // r
	write_byte(0); // g
	write_byte(255); // b
	write_byte(200);
	write_byte(0);
	message_end();
}

public fw_SecondaryAttack(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 5);
	if(!g_hasthunderbolt[id]){
		return HAM_IGNORED
	}
	return HAM_SUPERCEDE
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!g_hasthunderbolt[id]){
		return HAM_IGNORED
	}
	return HAM_SUPERCEDE
}

public fw_CmdStart(id, uc_handle, seed){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_AWP && g_hasthunderbolt[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_zoom[id] == 0){
				cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 0);
				emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_zoom.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				g_zoom[id] = 1
			}
			else if(g_zoom[id] == 1){
				cs_set_user_zoom(id, CS_SET_SECOND_ZOOM, 0);
				emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_zoom.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				g_zoom[id] = 2
			}
			else if(g_zoom[id] == 2){
				cs_set_user_zoom(id, CS_RESET_ZOOM, 1);
				emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_zoom.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				g_zoom[id] = 0
			}
		}
	}
}

public restore_zoom(data[]){
	new id
	id = data[0]
	if(g_zoom[id] == 1){
		cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 0);
		emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_zoom.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		g_reload[id] = false
	}
	else if(g_zoom[id] == 2){
		cs_set_user_zoom(id, CS_SET_SECOND_ZOOM, 0);
		emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_zoom.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		g_reload[id] = false
	}
}

public fw_PreThink(id){
	if(halflife_time() - 1.0 > g_delay[id]){
		static body
		static target
		get_user_aiming(id, target, body, 99999);
		if(g_zoom[id] != 0 && !g_reload[id]){
			if(is_user_alive(target) && zp_get_user_zombie(target)){
				emit_sound(id, CHAN_WEAPON, "weapons/sfsniper_insight1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				client_print(id, print_center, "TARGET ACQUIRED!");
			}
		}
		g_delay[id] = halflife_time()
	}
}

public fw_Spawn(id){
	if(g_hasthunderbolt[id]){
		g_thunderboltPammo[id] = get_pcvar_num(cvar_ammo)
		hud(id);
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasthunderbolt[id]){
		set_weapon_animation(id, 2);
		set_pdata_float(id, 46, 41/30.0, 4);
		set_pdata_float(id, 47, 41/30.0, 4);
		set_pdata_float(id, 48, 41/30.0, 4);
		set_pdata_float(id, 83, 41/30.0, 5);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 75487)
	{
		g_hasthunderbolt[id] = true;
		g_zoom[id] = false
		g_reload[id] = false
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		g_thunderboltPammo[id] = pev(weapon_entity, pev_iuser4)
		hud(id);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_awp.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_awp", entity);
	
	if(g_hasthunderbolt[owner] && pev_valid(wpn))
	{
		g_hasthunderbolt[owner] = false;
		g_zoom[owner] = false
		g_reload[owner] = false
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 75487);
		set_pev(wpn, pev_iuser4, g_thunderboltPammo[owner]);
		g_thunderboltPammo[owner] = 0
		engfunc(EngFunc_SetModel, entity, g_wmodel);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, g_deathmsg, _, id);
	write_string(bEnabled ? "bakoweapon_sfsniper" : "weapon_awp");
	write_byte(1)
	write_byte(bEnabled ? get_pcvar_num(cvar_ammo) : 30)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(2)
	write_byte(18)
	write_byte(0)
	message_end();
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
      if(is_user_connected(hitEnt) && zp_get_user_zombie(hitEnt)){
      	ExecuteHam(Ham_TakeDamage, hitEnt, id, id, dmg, DMG_BULLET|DMG_NEVERGIB);
	ExecuteHam(Ham_TraceBleed, hitEnt, dmg, VecDir, hTrace, DMG_BULLET|DMG_NEVERGIB);
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
