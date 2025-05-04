#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <xs>
#include <zombieplague>

new g_hasgungnir[33];
new g_gungnirammo[33];
new g_weaponmode[33];
new fire[33];
new g_ivic[3];
new cvar_altsecattack;
new cvar_primary_damage;
new cvar_secondary_damage;
new cvar_alt_secondary_damage;
new g_expc;
new g_expb;
new g_expa;
new traila;
new trailb;
new g_secdeath;
new gungnir;
new const g_vmodel[] = "models/v_gungnir.mdl"
new const g_pmodela[] = "models/p_gungnira.mdl"
new const g_pmodelb[] = "models/p_gungnirb.mdl"
new const g_wmodel[] = "models/w_gungnir.mdl"
new const g_missle[] = "models/gungnir_missile.mdl"
new const g_shootsound[] = "weapons/gungnir_shoot_loop.wav"
new const alt_missle[] = "sprites/ef_gungnir_missile.spr"

public plugin_init() {
	register_plugin("Gungnir", "1.0", "bako35");
	register_clcmd("bakoweapon_gungnir", "HookWeapon");
	register_event("DeathMsg", "death_player", "a");
	register_event("CurWeapon", "replace_models", "be", "1=1");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "fw_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "fw_ReloadWeapon", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m249", "fw_WeaponIdle");
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m249", "fw_WeaponIdle_2", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "fw_DeployPost", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_AddToPlayer", 1);
	g_secdeath = get_user_msgid("DeathMsg");
	cvar_altsecattack = register_cvar("gungnir_alt_secattack", "0");
	cvar_primary_damage = register_cvar("gungnir_primary_damage", "13.0");
	cvar_secondary_damage = register_clcmd("gungnir_secondary_damage", "56.0");
	cvar_alt_secondary_damage = register_cvar("gungnir_alt_secdamage", "25.0");
	gungnir = zp_register_extra_item("Gungnir", 0, ZP_TEAM_HUMAN|ZP_TEAM_SURVIVOR);
}

public plugin_precache(){
	precache_model(g_vmodel);
	precache_model(g_pmodela);
	precache_model(g_pmodelb);
	precache_model(g_wmodel);
	precache_model(g_missle);
	precache_sound(g_shootsound);
	precache_sound("weapons/gungnir_charge_loop.wav");
	precache_sound("weapons/gungnir_charge_shoot_exp.wav");
	precache_sound("weapons/gungnir_charge_shoot_exp2.wav");
	precache_sound("weapons/gungnir_charge_shoot1.wav");
	precache_sound("weapons/gungnir_charge_shoot2.wav");
	precache_sound("weapons/gungnir_draw.wav");
	precache_sound("weapons/gungnir_idle.wav");
	precache_sound("weapons/gungnir_reload.wav");
	precache_sound("weapons/gungnir_shoot_b.wav");
	precache_sound("weapons/gungnir_shoot_b_charge.wav");
	precache_sound("weapons/gungnir_shoot_b_exp.wav");
	precache_sound("weapons/gungnir_shoot_end.wav");
	precache_generic("sprites/muzzleflash81.spr");
	g_expc = precache_model("sprites/ef_gungnir_chargeexplo.spr");
	g_expb = precache_model("sprites/ef_gungnir_bexplo.spr");
	g_expa = precache_model("sprites/ef_gungnir_aexplo.spr");
	traila = precache_model("sprites/ef_gungnir_lightline1.spr");
	trailb = precache_model("sprites/ef_gungnir_lightline2.spr");
	precache_model(alt_missle);
}

public HookWeapon(const client){
	engclient_cmd(client, "weapon_m249");
	return PLUGIN_HANDLED
}

public client_connect(id){
	g_hasgungnir[id] = false
	g_weaponmode[id] = 1
	fire[id] = false
}

public client_disconnect(id){
	g_hasgungnir[id] = false
	g_weaponmode[id] = 1
	fire[id] = false
	UTIL_WeaponList(id, false);
}

public death_player(id){
	g_hasgungnir[read_data(2)] = false
	g_weaponmode[read_data(2)] = 1
	fire[read_data(2)] = false
	UTIL_WeaponList(read_data(2), false);
}

public zp_user_infected_post(id){
	g_hasgungnir[id] = false
	g_weaponmode[id] = 1
	fire[id] = false
	UTIL_WeaponList(id, false);
}

public zp_extra_item_selected(id, itemid){
	if(itemid == gungnir){
		give_gungnir(id);
	}
}

public zp_user_infected_post(id){
	g_hasgungnir[id] = false
	g_weaponmode[id] = 1
	fire[id] = false
}

public give_gungnir(id){
	if(is_user_alive(id) && !g_hasgungnir[id]){
		if(user_has_weapon(id, CSW_M249)){
			drop_weapon(id);
		}
		g_hasgungnir[id] = true
		g_weaponmode[id] = 1
		fire[id] = false
		UTIL_WeaponList(id, true);
		new wpnid = give_item(id, "weapon_m249");
		cs_set_weapon_ammo(wpnid, 50);
		cs_set_user_bpammo(id, CSW_M249, 200);
		replace_models(id);
	}
}

public replace_models(id){
	new svd = read_data(2);
	if(g_hasgungnir[id] && svd == CSW_M249){
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodela);
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

public fw_PrimaryAttack(weapon_entity){
	new id
	new Float:fCurTime
	new Float:fSound
	id = get_pdata_cbase(weapon_entity, 41, 5)
	global_get(glb_time, fCurTime)
	pev(weapon_entity, pev_fuser1, fSound)
	g_gungnirammo[id] = cs_get_weapon_ammo(weapon_entity);
	if(!g_hasgungnir[id]){
		return HAM_IGNORED;
	}
	if(!g_gungnirammo[id]){
		ExecuteHam(Ham_Weapon_PlayEmptySound, weapon_entity);
		set_pdata_float(id, 83, 0.2, 5);
	}
	if(g_weaponmode[id] == 1 && fire[id] && g_gungnirammo[id]){
		set_pdata_float(id, 83, 0.1, 5);
		set_pdata_float(weapon_entity, 46, 0.1, 4);
		set_pdata_float(weapon_entity, 48, 0.6, 4);
		set_weapon_animation(id, 4);
		if(fSound < fCurTime){
			emit_sound(id, CHAN_WEAPON, g_shootsound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_pev(weapon_entity, pev_fuser1, fCurTime + 1.0);
		}
		set_pdata_int(weapon_entity, 51, g_gungnirammo[id] - 1, 4);
		PrimaryAttack(id);
	}
	if(g_weaponmode[id] == 1 && !fire[id]){
		set_pdata_int(weapon_entity, 51, g_gungnirammo[id], 4);
		set_weapon_animation(id, 3);
		set_pdata_float(id, 83, 7/30.0, 5);
		fire[id] = true
	}
	if(g_weaponmode[id] == 2 && !fire[id] && !get_pcvar_num(cvar_altsecattack)){
		set_pdata_float(id, 83, 94/30.0, 5);
		set_weapon_animation(id, 8);
		set_player_animation(id, "shoot_grenade");
		emit_sound(id, CHAN_WEAPON, "weapons/gungnir_charge_shoot1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		SecondaryAttack(id);
		if(g_gungnirammo[id] >= 5){
			set_pdata_int(weapon_entity, 51, g_gungnirammo[id] - 5, 4);
		}
		else if(g_gungnirammo[id] < 5){
			set_pdata_int(weapon_entity, 51, 0, 4);
		}
		set_pev(id, pev_weaponmodel2, g_pmodela);
		g_weaponmode[id] = 1
	}
	return HAM_SUPERCEDE;
}

public PrimaryAttack(id){
	new Float:fOrigin[3], Float:fEnd[3], Float:LOL[3][3]
	new k
	new pEntity = -1
	pev(id, pev_origin, fOrigin);
	Get_Postion(id, 64.0, 0.0, 0.0, fEnd);
		
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTPOINT)
	write_short(id|0x1000)
	engfunc(EngFunc_WriteCoord, fEnd[0])
	engfunc(EngFunc_WriteCoord, fEnd[1])
	engfunc(EngFunc_WriteCoord, fEnd[2])
	write_short(trailb)
	write_byte(0) // framerate
	write_byte(0) // framerate
	write_byte(1) // life
	write_byte(40)  // width
	write_byte(10)// noise
	write_byte(26)// r
	write_byte(164)// g
	write_byte(255)// b
	write_byte(255)	// alpha
	write_byte(255)	// speed
	message_end()
		
	for(k = 0; k < 3; k++){
		while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, 256.0)) != 0){
			if(pev(pEntity, pev_takedamage) == DAMAGE_NO){
				continue
			}
			if(pEntity == id){
				continue
			}
			if(k == 1 && pEntity == g_ivic[0]){
				continue
			}
			if(k == 2 && (pEntity == g_ivic[0] || pEntity == g_ivic[1])){
				continue
			}
			if(pev_valid(pEntity)){
				new Float:tempOrigin[3]
				pev(pEntity, pev_origin, tempOrigin)
				if(get_distance_f(fOrigin, tempOrigin) < 256.0){
					g_ivic[k] = pEntity
				}
			}
			pev(g_ivic[k], pev_origin, LOL[k])
			if(is_user_alive(g_ivic[k]) && entity_range(id, g_ivic[k]) < 256.0 && zp_get_user_zombie(g_ivic[k])){
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
				write_byte(TE_EXPLOSION)
				engfunc(EngFunc_WriteCoord, LOL[k][0])
				engfunc(EngFunc_WriteCoord, LOL[k][1])
				engfunc(EngFunc_WriteCoord, LOL[k][2] - 15.0)
				write_short(g_expa)
				write_byte(2)
				write_byte(30)
				write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
				message_end()
					
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
				write_byte(TE_BEAMPOINTS)
				engfunc(EngFunc_WriteCoord, LOL[k][0])
				engfunc(EngFunc_WriteCoord, LOL[k][1])
				engfunc(EngFunc_WriteCoord, LOL[k][2])
				engfunc(EngFunc_WriteCoord, fEnd[0])
				engfunc(EngFunc_WriteCoord, fEnd[1])
				engfunc(EngFunc_WriteCoord, fEnd[2])
				write_short(g_expa)
				write_byte(0)		// byte (starting frame) 
				write_byte(10)		// byte (frame rate in 0.1's) 
				write_byte(1)		// byte (life in 0.1's) 
				write_byte(55)		// byte (line width in 0.1's) 
				write_byte(17)		// byte (noise amplitude in 0.01's) 
				write_byte(26)		// (R)
				write_byte(164)		// (G)
				write_byte(255)		// (B)
				write_byte(255)		// byte (brightness)
				write_byte(10)		// byte (scroll speed in 0.1s)
				message_end()
					
				ExecuteHamB(Ham_TakeDamage, g_ivic[k], id, id, get_pcvar_float(cvar_primary_damage), DMG_SHOCK|DMG_NEVERGIB);
			}
		}
	}
}

public SecondaryAttack(id){
	new rocket
	rocket = create_entity("info_target")
	entity_set_string(rocket, EV_SZ_classname, "gungnir_missile");
	entity_set_model(rocket, g_missle);
	entity_set_size(rocket, Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0});
	entity_set_int(rocket, EV_INT_movetype, MOVETYPE_FLY);
	entity_set_int(rocket, EV_INT_solid, SOLID_BBOX);
	
	new Float:vsrc[3]
	entity_get_vector(id, EV_VEC_origin, vsrc);
	
	new Float:aim[3]
	new Float:origin[3]
	VelocityByAim(id, 64, aim);
	entity_get_vector(id, EV_VEC_origin, origin);
	
	vsrc[0] += aim[0]
	vsrc[1] += aim[1]
	entity_set_origin(rocket, vsrc);
	
	new Float:velocity[3]
	new Float:angles[3]
	VelocityByAim(id, 1500, velocity);
	entity_set_vector(rocket, EV_VEC_velocity, velocity);
	vector_to_angle(velocity, angles);
	entity_set_vector(rocket, EV_VEC_angles, angles);
	entity_set_edict(rocket, EV_ENT_owner, id);
	entity_set_float(rocket, EV_FL_takedamage, 1.0);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(rocket)
	write_short(traila)
	write_byte(50)
	write_byte(10)
	write_byte(225)
	write_byte(225)
	write_byte(255)
	write_byte(255)
	message_end()
}

public AltSecondaryAttack(id, Float:speed){
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
	entity_set_string(idxent, EV_SZ_classname, "gungnir_ball");
	engfunc(EngFunc_SetModel, idxent, alt_missle);
	set_pev(idxent, pev_mins, Float:{-5.0, -5.0, -5.0});
	set_pev(idxent, pev_maxs, Float:{5.0, 5.0, 5.0});
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

public pfn_touch(ptr, ptd){
	if(is_valid_ent(ptr)){
		new classname[32]
		entity_get_string(ptr, EV_SZ_classname, classname, 31);
		if(equal(classname, "gungnir_missile")){
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			if(random_num(1, 2) == 1){
				emit_sound(ptr, CHAN_ITEM, "weapons/gungnir_charge_shoot_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else{
				emit_sound(ptr, CHAN_ITEM, "weapons/gungnir_charge_shoot_exp2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			radiusC(ptr);
			remove_entity(ptr);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iorigin)
			write_byte(TE_EXPLOSION)
			write_coord(iorigin[0])
			write_coord(iorigin[1])
			write_coord(iorigin[2])
			write_short(g_expc)
			write_byte(10)
			write_byte(15)
			write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
			message_end()
			
			if(is_valid_ent(ptd)){
				new classname2[32]
				entity_get_string(ptd, EV_SZ_classname, classname2, 31);
				if(equal(classname2, "func_breakable")){
					force_use(ptr, ptd);
				}
				remove_entity(ptr);
			}
		}
		if(equal(classname, "gungnir_ball")){
			new Float:forigin[3]
			new iorigin[3]
			entity_get_vector(ptr, EV_VEC_origin, forigin);
			FVecIVec(forigin, iorigin);
			emit_sound(ptr, CHAN_ITEM, "weapons/gungnir_shoot_b_exp.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			radiusB(ptr);
			remove_entity(ptr);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY,iorigin)
			write_byte(TE_EXPLOSION)
			write_coord(iorigin[0])
			write_coord(iorigin[1])
			write_coord(iorigin[2])
			write_short(g_expb)
			write_byte(10)
			write_byte(15)
			write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
			message_end()
			
			if(is_valid_ent(ptd)){
				new classname2[32]
				entity_get_string(ptd, EV_SZ_classname, classname2, 31);
				if(equal(classname2, "func_breakable")){
					force_use(ptr, ptd);
				}
				remove_entity(ptr);
	}
	return PLUGIN_CONTINUE
}
}
}

public radiusC(entity){
	new id = entity_get_edict(entity, EV_ENT_owner)
	for(new i = 1; i < 33; i++){
		if(is_user_alive(i)){
			new distance
			distance = floatround(entity_range(entity, i))
			if(distance <= 25){ // 100 default
				if(get_user_team(id) != get_user_team(i)){
					Fake_KnockBack(id, i, 50.0);
					set_msg_block(g_secdeath, BLOCK_SET);
					ExecuteHamB(Ham_TakeDamage, i, 0, id, get_pcvar_float(cvar_secondary_damage), DMG_BLAST|DMG_SHOCK|DMG_NEVERGIB);
					set_msg_block(g_secdeath, BLOCK_NOT);
					if(get_user_health(i) <= 0){
						SendDeathMsg(id, i);
					}
				}
			}
		}
	}
}

public radiusB(entity){
	new id = entity_get_edict(entity, EV_ENT_owner)
	for(new i = 1; i < 33; i++){
		if(is_user_alive(i)){
			new distance
			distance = floatround(entity_range(entity, i))
			if(distance <= 100){ // 100 default
				if(get_user_team(id) != get_user_team(i)){
					Fake_KnockBack(id, i, 1.0);
					set_msg_block(g_secdeath, BLOCK_SET);
					ExecuteHamB(Ham_TakeDamage, i, 0, id, get_pcvar_float(cvar_alt_secondary_damage), DMG_BLAST|DMG_SHOCK|DMG_NEVERGIB);
					set_msg_block(g_secdeath, BLOCK_NOT);
					if(get_user_health(i) <= 0){
						SendDeathMsg(id, i);
					}
				}
			}
		}
	}
}

public fw_CmdStart(id, uc_handle, seed){	
	if(!(get_uc(uc_handle, UC_Buttons) & IN_ATTACK) && is_user_alive(id) && g_hasgungnir[id] && g_weaponmode[id] == 1){
		if((pev(id, pev_oldbuttons) & IN_ATTACK) && pev(id, pev_weaponanim) == 4){
			set_weapon_animation(id, 5);
			emit_sound(id, CHAN_WEAPON, "weapons/gungnir_shoot_end.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			fire[id] = false
			return FMRES_HANDLED
		}
	}
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M249 && g_hasgungnir[id]){
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2)){
			if(g_weaponmode[id] == 1 && !get_pcvar_num(cvar_altsecattack)){
				set_weapon_animation(id, 7);
				set_pdata_float(id, 83, 61/30.0, 5);
				set_player_animation(id, "aim_grenade");
				set_pev(id, pev_weaponmodel2, g_pmodelb);
				g_weaponmode[id] = 2
				return FMRES_HANDLED
			}
			else if(get_pcvar_num(cvar_altsecattack) && g_gungnirammo[id]){
				static weapon
				weapon = fm_get_user_weapon_entity(id, CSW_M249)
				g_gungnirammo[id] = cs_get_weapon_ammo(weapon);
				if(g_gungnirammo[id] >= 5){
					set_weapon_animation(id, 6);
					//set_pdata_float(id, 83, 21/30.0, 5);
					emit_sound(id, CHAN_WEAPON, "weapons/gungnir_shoot_b.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					set_pdata_int(weapon, 51, g_gungnirammo[id] - 5, 4);
					AltSecondaryAttack(id, 1000.0);
				}
				if(g_gungnirammo[id] < 5){
					set_weapon_animation(id, 6);
					//set_pdata_float(id, 83, 21/30.0, 5);
					emit_sound(id, CHAN_WEAPON, "weapons/gungnir_shoot_b.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					set_pdata_int(weapon, 51, 0, 4);
					AltSecondaryAttack(id, 1000.0);
				}
				return FMRES_HANDLED
			}
			else if(get_pcvar_num(cvar_altsecattack) && !g_gungnirammo[id]){
				static weapon
				weapon = fm_get_user_weapon_entity(id, CSW_M249)
				ExecuteHam(Ham_Weapon_PlayEmptySound, weapon);
			}
		}
	}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle){
	if(is_user_alive(id) && get_user_weapon(id) == CSW_M249 && g_hasgungnir[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001);
	}
}

public fw_ItemPostFrame(weapon_entity){
	new id = pev(weapon_entity, pev_owner);
	if(is_user_alive(id) && g_hasgungnir[id]){
		static iclipex = 50
		new Float:flNextAttack = get_pdata_float(id, 83, 5);
		new ibpammo = cs_get_user_bpammo(id, CSW_M249);
		new iclip = get_pdata_int(weapon_entity, 51, 4);
		new finreload = get_pdata_int(weapon_entity, 54, 4);
		if(finreload && flNextAttack <= 0.0){
			new clp = min(iclipex - iclip, ibpammo);
			set_pdata_int(weapon_entity, 51, iclip + clp, 4);
			cs_set_user_bpammo(id, CSW_M249, ibpammo-clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
		}
	}
}

public fw_ReloadWeapon(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasgungnir[id]){
		set_weapon_animation(id, 1);
		set_pdata_float(id, 46, 61/30.0, 4);
		set_pdata_float(id, 47, 61/30.0, 4);
		set_pdata_float(id, 48, 61/30.0, 4);
		set_pdata_float(id, 83, 61/30.0, 5);
		g_weaponmode[id] = 1
	}
}

public fw_WeaponIdle(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(g_hasgungnir[id] && g_weaponmode[id] == 2 && !get_pcvar_num(cvar_altsecattack)){
		set_player_animation(id, "aim_grenade");
		set_pev(id, pev_weaponmodel2, g_pmodelb);
	}
	return HAM_SUPERCEDE
}

public fw_WeaponIdle_2(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4);
	if(!is_user_alive(id) || !g_hasgungnir[id] || get_user_weapon(id) != CSW_M249){
		return HAM_IGNORED
	}
	if(g_hasgungnir[id] && g_weaponmode[id] == 1 && get_pdata_float(weapon_entity, 48, 4) <= 0,2){
		set_weapon_animation(id, 0);
		set_pdata_float(weapon_entity, 48, 91/30.0, 4);
		return HAM_SUPERCEDE
	}
	if(g_hasgungnir[id] && g_weaponmode[id] == 2 && get_pdata_float(weapon_entity, 48, 4) <= 0,2){
		set_weapon_animation(id, 9);
		set_pdata_float(weapon_entity, 48, 61/30.0, 4);
		return HAM_SUPERCEDE
	}
}

public fw_DeployPost(weapon_entity){
	new id
	id = get_pdata_cbase(weapon_entity, 41, 4)
	if(g_hasgungnir[id] && g_weaponmode[id] == 1){
		set_weapon_animation(id, 2);
		set_pdata_float(id, 46, 31/30.0, 4);
		set_pdata_float(id, 47, 31/30.0, 4);
		set_pdata_float(id, 48, 31/30.0, 4);
		set_pdata_float(id, 83, 31/30.0, 5);
	}
	else if(g_weaponmode[id] == 2 && !get_pcvar_num(cvar_altsecattack)){
		set_weapon_animation(id, 7);
		set_pdata_float(id, 46, 61/30.0, 4);
		set_pdata_float(id, 47, 61/30.0, 4);
		set_pdata_float(id, 48, 61/30.0, 4);
		set_pdata_float(id, 83, 61/30.0, 5);
	}
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == 21376969)
	{
		g_hasgungnir[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		UTIL_WeaponList(id, true);
		g_weaponmode[id] = 1
		fire[id] = false
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, "models/w_m249.mdl")) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_m249", entity);
	
	if(g_hasgungnir[owner] && pev_valid(wpn)){
		g_hasgungnir[owner] = false;
		UTIL_WeaponList(owner, false);
		set_pev(wpn, pev_impulse, 21376969);
		fire[owner] = false
		g_weaponmode[owner] = 1
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

stock Get_Postion(id,Float:forw, Float:right, Float:up, Float:vStart[]){
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
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

stock Float:Blah(Float:start[3], Float:end[3], ignore_ent){
	static ptr
	ptr = create_tr2()
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return get_distance_f(end, EndPos)
} 

stock SendDeathMsg(attacker, victim){ // Sends death message
	message_begin(MSG_BROADCAST, g_secdeath)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("m249") // killer's weapon
	message_end()
}

stock set_player_animation(id, const AnimName[], Float:rate=1.0){
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops, Anim2[64]
	if(!(pev(id, pev_flags) & FL_DUCKING)) format(Anim2, 63, "ref_%s", AnimName)
	else format(Anim2, 63, "crouch_%s", AnimName)

	if ((AnimNum=lookup_sequence(id,Anim2,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0
	
	if (!Loops || (Loops && pev(id,pev_sequence)!=AnimNum))
	{
		set_pev(id, pev_gaitsequence, AnimNum)
		set_pev(id, pev_sequence, AnimNum)
		set_pev(id, pev_frame, 0.0)
		set_pev(id, pev_animtime, get_gametime())
	}
	set_pev(id, pev_framerate, rate)

	set_pdata_int(id, 40, Loops, 4)
	set_pdata_int(id, 39, 0, 4)

	set_pdata_float(id, 36, FrameRate, 4)
	set_pdata_float(id, 37, GroundSpeed, 4)
	set_pdata_float(id, 38, get_gametime(), 4)

	set_pdata_int(id, 73, 28, 5)
	set_pdata_int(id, 74, 28, 5)
	set_pdata_float(id, 220, get_gametime(), 5)
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

stock Fake_KnockBack(id, iVic, Float:iKb){
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}

stock UTIL_WeaponList(id, const bool: bEnabled){
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id);
	write_string(bEnabled ? "bakoweapon_gungnir" : "weapon_m249");
	write_byte(3)
	write_byte(200)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(4)
	write_byte(20)
	write_byte(0)
	message_end();
}
