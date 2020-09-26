// SONIC ROBO BLAST 2
//-----------------------------------------------------------------------------
// Copyright (C) 1998-2000 by DooM Legacy Team.
// Copyright (C) 1999-2020 by Sonic Team Junior.
//
// This program is free software distributed under the
// terms of the GNU General Public License, version 2.
// See the 'LICENSE' file for more details.
//-----------------------------------------------------------------------------
/// \file m_perfstats.h
/// \brief Performance measurement tools.

#ifndef __M_PERFSTATS_H__
#define __M_PERFSTATS_H__

extern int ps_tictime;

extern int ps_playerthink_time;
extern int ps_thinkertime;
#ifdef HAVE_BLUA
extern int ps_lua_thinkframe_time;
#endif

void M_DrawPerfStats(void);

#endif