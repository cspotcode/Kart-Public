// SONIC ROBO BLAST 2
//-----------------------------------------------------------------------------
// Copyright (C) 1998-2000 by DooM Legacy Team.
// Copyright (C) 1999-2020 by Sonic Team Junior.
//
// This program is free software distributed under the
// terms of the GNU General Public License, version 2.
// See the 'LICENSE' file for more details.
//-----------------------------------------------------------------------------
/// \file m_perfstats.c
/// \brief Performance measurement tools.

#include "m_perfstats.h"
#include "doomdef.h"
#include "v_video.h"
#include "i_video.h"
#include "d_netcmd.h"
#include "r_main.h"
#include "i_system.h"

#ifdef HWRENDER
#include "hardware/hw_main.h"
#endif

int rs_tictime = 0;

void M_DrawPerfStats(void)
{
	if (cv_renderstats.value)
	{
		char s[50];
		int currenttime = I_GetTimeMicros();
		int frametime = currenttime - rs_prevframetime;
		int divisor = 1;
		rs_prevframetime = currenttime;

		if (rs_rendercalltime > 10000)
			divisor = 1000;

		snprintf(s, sizeof s - 1, "frmtime %d", frametime / divisor);
		V_DrawThinString(20, 10, V_MONOSPACE | V_YELLOWMAP, s);
		snprintf(s, sizeof s - 1, "drwtime %d", rs_rendercalltime / divisor);
		V_DrawThinString(20, 20, V_MONOSPACE | V_YELLOWMAP, s);
		snprintf(s, sizeof s - 1, "bsptime %d", rs_bsptime / divisor);
		V_DrawThinString(24, 30, V_MONOSPACE | V_YELLOWMAP, s);
		snprintf(s, sizeof s - 1, "bspcall %d", rs_numbspcalls);
		V_DrawThinString(90, 10, V_MONOSPACE | V_BLUEMAP, s);
		snprintf(s, sizeof s - 1, "sprites %d", rs_numsprites);
		V_DrawThinString(90, 20, V_MONOSPACE | V_BLUEMAP, s);
		snprintf(s, sizeof s - 1, "drwnode %d", rs_numdrawnodes);
		V_DrawThinString(90, 30, V_MONOSPACE | V_BLUEMAP, s);
		snprintf(s, sizeof s - 1, "plyobjs %d", rs_numpolyobjects);
		V_DrawThinString(90, 40, V_MONOSPACE | V_BLUEMAP, s);
#ifdef HWRENDER
		if (rendermode == render_opengl) // OpenGL specific stats
		{
			snprintf(s, sizeof s - 1, "nodesrt %d", rs_hw_nodesorttime / divisor);
			V_DrawThinString(24, 40, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "nodedrw %d", rs_hw_nodedrawtime / divisor);
			V_DrawThinString(24, 50, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "sprsort %d", rs_hw_spritesorttime / divisor);
			V_DrawThinString(24, 60, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "sprdraw %d", rs_hw_spritedrawtime / divisor);
			V_DrawThinString(24, 70, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "ui      %d", rs_uitime / divisor);
			V_DrawThinString(20, 80, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "finupdt %d", rs_swaptime / divisor);
			V_DrawThinString(20, 90, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "tic     %d", rs_tictime / divisor);
			V_DrawThinString(20, 105, V_MONOSPACE | V_GRAYMAP, s);
			if (cv_grbatching.value)
			{
				snprintf(s, sizeof s - 1, "batsort %d", rs_hw_batchsorttime / divisor);
				V_DrawThinString(90, 55, V_MONOSPACE | V_REDMAP, s);
				snprintf(s, sizeof s - 1, "batdraw %d", rs_hw_batchdrawtime / divisor);
				V_DrawThinString(90, 65, V_MONOSPACE | V_REDMAP, s);

				snprintf(s, sizeof s - 1, "polygon %d", rs_hw_numpolys);
				V_DrawThinString(155, 10, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "drwcall %d", rs_hw_numcalls);
				V_DrawThinString(155, 20, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "shaders %d", rs_hw_numshaders);
				V_DrawThinString(155, 30, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "vertex  %d", rs_hw_numverts);
				V_DrawThinString(155, 40, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "texture %d", rs_hw_numtextures);
				V_DrawThinString(220, 10, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "polyflg %d", rs_hw_numpolyflags);
				V_DrawThinString(220, 20, V_MONOSPACE | V_PURPLEMAP, s);
				snprintf(s, sizeof s - 1, "colors  %d", rs_hw_numcolors);
				V_DrawThinString(220, 30, V_MONOSPACE | V_PURPLEMAP, s);
			}
		}
		else // software specific stats
#endif
		{
			snprintf(s, sizeof s - 1, "portals %d", rs_sw_portaltime / divisor);
			V_DrawThinString(24, 40, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "planes  %d", rs_sw_planetime / divisor);
			V_DrawThinString(24, 50, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "masked  %d", rs_sw_maskedtime / divisor);
			V_DrawThinString(24, 60, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "ui      %d", rs_uitime / divisor);
			V_DrawThinString(20, 70, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "finupdt %d", rs_swaptime / divisor);
			V_DrawThinString(20, 80, V_MONOSPACE | V_YELLOWMAP, s);
			snprintf(s, sizeof s - 1, "tic     %d", rs_tictime / divisor);
			V_DrawThinString(20, 95, V_MONOSPACE | V_GRAYMAP, s);
		}
	}
}
