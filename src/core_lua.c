#include "fov/fov.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "auxiliar.h"
#include "types.h"
#include "script.h"
#include "display.h"
#include "SFMT.h"
#include <SDL.h>
#include <SDL_ttf.h>

/******************************************************************
 ******************************************************************
 *                              FOV                               *
 ******************************************************************
 ******************************************************************/
struct lua_fov
{
	fov_settings_type fov_settings;
	int apply_ref;
	int opaque_ref;
	int map_ref;
};

static void map_seen(void *m, int x, int y, int dx, int dy, int radius, void *src)
{
	struct lua_fov *fov = (struct lua_fov *)m;
	radius--;
	if (dx*dx + dy*dy <= radius*radius + 1)
	{	// circular view - can be changed if you like

	lua_rawgeti(L, LUA_REGISTRYINDEX, fov->apply_ref);
	lua_rawgeti(L, LUA_REGISTRYINDEX, fov->map_ref);
	lua_pushnumber(L, x);
	lua_pushnumber(L, y);
	lua_call(L, 3, 0);
	}
}

static bool map_opaque(void *m, int x, int y)
{
	struct lua_fov *fov = (struct lua_fov *)m;

	lua_rawgeti(L, LUA_REGISTRYINDEX, fov->opaque_ref);
	lua_rawgeti(L, LUA_REGISTRYINDEX, fov->map_ref);
	lua_pushnumber(L, x);
	lua_pushnumber(L, y);
	lua_call(L, 3, 1);
	bool res = lua_toboolean(L, -1);
	lua_pop(L, 1);
	return res;
}

static int lua_new_fov(lua_State *L)
{
	int map_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	int apply_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	int opaque_ref = luaL_ref(L, LUA_REGISTRYINDEX);

	struct lua_fov *fov = (struct lua_fov*)lua_newuserdata(L, sizeof(struct lua_fov));
	auxiliar_setclass(L, "fov{core}", -1);
	fov->apply_ref = apply_ref;
	fov->opaque_ref = opaque_ref;
	fov->map_ref = map_ref;
	fov_settings_init(&(fov->fov_settings));
	fov_settings_set_opacity_test_function(&(fov->fov_settings), map_opaque);
	fov_settings_set_apply_lighting_function(&(fov->fov_settings), map_seen);

	return 1;
}

static int lua_free_fov(lua_State *L)
{
	struct lua_fov *fov = (struct lua_fov*)auxiliar_checkclass(L, "fov{core}", 1);
	fov_settings_free(&(fov->fov_settings));
	luaL_unref(L, LUA_REGISTRYINDEX, fov->apply_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov->opaque_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov->map_ref);
	lua_pushnumber(L, 1);
	return 1;
}

static int lua_fov(lua_State *L)
{
	struct lua_fov *fov = (struct lua_fov*)auxiliar_checkclass(L, "fov{core}", 1);
	int x = luaL_checknumber(L, 2);
	int y = luaL_checknumber(L, 3);
	int radius = luaL_checknumber(L, 4);

	fov_circle(&(fov->fov_settings), fov, NULL, x, y, radius+1);
	map_seen(fov, x, y, 0, 0, radius, NULL);
	return 0;
}

static int lua_fov_calc_circle(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	int y = luaL_checknumber(L, 2);
	int radius = luaL_checknumber(L, 3);
	struct lua_fov fov;
	fov.map_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	fov.apply_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	fov.opaque_ref = luaL_ref(L, LUA_REGISTRYINDEX);

	fov_settings_init(&(fov.fov_settings));
	fov_settings_set_opacity_test_function(&(fov.fov_settings), map_opaque);
	fov_settings_set_apply_lighting_function(&(fov.fov_settings), map_seen);
	fov_circle(&(fov.fov_settings), &fov, NULL, x, y, radius+1);
	map_seen(&fov, x, y, 0, 0, radius, NULL);
	fov_settings_free(&(fov.fov_settings));

	luaL_unref(L, LUA_REGISTRYINDEX, fov.apply_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov.opaque_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov.map_ref);

	return 0;
}

static int lua_fov_calc_beam(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	int y = luaL_checknumber(L, 2);
	int radius = luaL_checknumber(L, 3);
	int direction = luaL_checknumber(L, 4);
	float angle = luaL_checknumber(L, 5);
	struct lua_fov fov;
	fov.map_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	fov.apply_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	fov.opaque_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	int dir = 0;

	switch (direction)
	{
	case 1: dir = FOV_SOUTHWEST; break;
	case 2: dir = FOV_SOUTH; break;
	case 3: dir = FOV_SOUTHEAST; break;
	case 4: dir = FOV_WEST; break;
	case 6: dir = FOV_EAST; break;
	case 7: dir = FOV_NORTHWEST; break;
	case 8: dir = FOV_NORTH; break;
	case 9: dir = FOV_NORTHEAST; break;
	}

	fov_settings_init(&(fov.fov_settings));
	fov_settings_set_opacity_test_function(&(fov.fov_settings), map_opaque);
	fov_settings_set_apply_lighting_function(&(fov.fov_settings), map_seen);
	fov_beam(&(fov.fov_settings), &fov, NULL, x, y, radius+1, dir, angle);
	map_seen(&fov, x, y, 0, 0, radius, NULL);
	fov_settings_free(&(fov.fov_settings));

	luaL_unref(L, LUA_REGISTRYINDEX, fov.apply_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov.opaque_ref);
	luaL_unref(L, LUA_REGISTRYINDEX, fov.map_ref);

	return 0;
}

static const struct luaL_reg fovlib[] =
{
	{"new", lua_new_fov},
	{"calc_circle", lua_fov_calc_circle},
	{"calc_beam", lua_fov_calc_beam},
	{NULL, NULL},
};

static const struct luaL_reg fov_reg[] =
{
	{"__gc", lua_free_fov},
	{"close", lua_free_fov},
	{"__call", lua_fov},
	{NULL, NULL},
};

/******************************************************************
 ******************************************************************
 *                             Mouse                              *
 ******************************************************************
 ******************************************************************/
static int lua_get_mouse(lua_State *L)
{
	int x = 0, y = 0;
	int buttons = SDL_GetMouseState(&x, &y);

	lua_pushnumber(L, x);
	lua_pushnumber(L, y);

	return 2;
}
extern int current_mousehandler;
static int lua_set_current_mousehandler(lua_State *L)
{
	if (current_mousehandler != LUA_NOREF)
		luaL_unref(L, LUA_REGISTRYINDEX, current_mousehandler);

	if (lua_isnil(L, 1))
		current_mousehandler = LUA_NOREF;
	else
		current_mousehandler = luaL_ref(L, LUA_REGISTRYINDEX);

	return 0;
}
static const struct luaL_reg mouselib[] =
{
	{"get", lua_get_mouse},
	{"set_current_handler", lua_set_current_mousehandler},
	{NULL, NULL},
};

/******************************************************************
 ******************************************************************
 *                              Keys                              *
 ******************************************************************
 ******************************************************************/
extern int current_keyhandler;
static int lua_set_current_keyhandler(lua_State *L)
{
	if (current_keyhandler != LUA_NOREF)
		luaL_unref(L, LUA_REGISTRYINDEX, current_keyhandler);

	if (lua_isnil(L, 1))
		current_keyhandler = LUA_NOREF;
	else
		current_keyhandler = luaL_ref(L, LUA_REGISTRYINDEX);

	return 0;
}
static const struct luaL_reg keylib[] =
{
	{"set_current_handler", lua_set_current_keyhandler},
	{NULL, NULL},
};

/******************************************************************
 ******************************************************************
 *                              Game                              *
 ******************************************************************
 ******************************************************************/
extern int current_game;
static int lua_set_current_game(lua_State *L)
{
	if (current_game != LUA_NOREF)
		luaL_unref(L, LUA_REGISTRYINDEX, current_game);

	if (lua_isnil(L, 1))
		current_game = LUA_NOREF;
	else
		current_game = luaL_ref(L, LUA_REGISTRYINDEX);

	return 0;
}
static const struct luaL_reg gamelib[] =
{
	{"set_current_game", lua_set_current_game},
	{NULL, NULL},
};

/******************************************************************
 ******************************************************************
 *                           Display                              *
 ******************************************************************
 ******************************************************************/

static int sdl_fullscreen(lua_State *L)
{
	SDL_WM_ToggleFullScreen(screen);
	return 0;
}

static int sdl_screen_size(lua_State *L)
{
	lua_pushnumber(L, screen->w);
	lua_pushnumber(L, screen->h);
	return 2;
}

static int sdl_new_font(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);
	int size = luaL_checknumber(L, 2);

	TTF_Font **f = (TTF_Font**)lua_newuserdata(L, sizeof(TTF_Font*));
	auxiliar_setclass(L, "sdl{font}", -1);

	*f = TTF_OpenFontRW(PHYSFSRWOPS_openRead(name), TRUE, size);

	return 1;
}

static int sdl_free_font(lua_State *L)
{
	TTF_Font **f = (TTF_Font**)auxiliar_checkclass(L, "sdl{font}", 1);
	TTF_CloseFont(*f);
	lua_pushnumber(L, 1);
	return 1;
}

static int sdl_font_size(lua_State *L)
{
	TTF_Font **f = (TTF_Font**)auxiliar_checkclass(L, "sdl{font}", 1);
	const char *str = luaL_checkstring(L, 2);
	int w, h;

	if (!TTF_SizeUTF8(*f, str, &w, &h))
	{
		lua_pushnumber(L, w);
		lua_pushnumber(L, h);
		return 2;
	}
	return 0;
}

static int sdl_font_height(lua_State *L)
{
	TTF_Font **f = (TTF_Font**)auxiliar_checkclass(L, "sdl{font}", 1);
	lua_pushnumber(L, TTF_FontHeight(*f));
	return 1;
}

static int sdl_font_lineskip(lua_State *L)
{
	TTF_Font **f = (TTF_Font**)auxiliar_checkclass(L, "sdl{font}", 1);
	lua_pushnumber(L, TTF_FontLineSkip(*f));
	return 1;
}

static int sdl_surface_drawstring(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	TTF_Font **f = (TTF_Font**)auxiliar_checkclass(L, "sdl{font}", 2);
	const char *str = luaL_checkstring(L, 3);
	int x = luaL_checknumber(L, 4);
	int y = luaL_checknumber(L, 5);
	int r = luaL_checknumber(L, 6);
	int g = luaL_checknumber(L, 7);
	int b = luaL_checknumber(L, 8);

	SDL_Color color = {r,g,b};
	SDL_Surface *txt = TTF_RenderUTF8_Solid(*f, str, color);
	if (txt)
	{
		sdlDrawImage(*s, txt, x, y);
		SDL_FreeSurface(txt);
	}

	return 0;
}

static int sdl_new_surface(lua_State *L)
{
	int w = luaL_checknumber(L, 1);
	int h = luaL_checknumber(L, 2);

	SDL_Surface **s = (SDL_Surface**)lua_newuserdata(L, sizeof(SDL_Surface*));
	auxiliar_setclass(L, "sdl{surface}", -1);

	*s = SDL_CreateRGBSurface(
		screen->flags,
		w,
		h,
		screen->format->BitsPerPixel,
		screen->format->Rmask,
		screen->format->Gmask,
		screen->format->Bmask,
		screen->format->Amask
		);
	return 1;
}

static int sdl_load_image(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);

	SDL_Surface **s = (SDL_Surface**)lua_newuserdata(L, sizeof(SDL_Surface*));
	auxiliar_setclass(L, "sdl{surface}", -1);

	*s = IMG_Load_RW(PHYSFSRWOPS_openRead(name), TRUE);

	return 1;
}

static int sdl_free_surface(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	SDL_FreeSurface(*s);
	lua_pushnumber(L, 1);
	return 1;
}

static int lua_display_char(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	const char *c = luaL_checkstring(L, 2);
	int x = luaL_checknumber(L, 3);
	int y = luaL_checknumber(L, 4);
	int r = luaL_checknumber(L, 5);
	int g = luaL_checknumber(L, 6);
	int b = luaL_checknumber(L, 7);

	display_put_char(*s, c[0], x, y, r, g, b);

	return 0;
}

static int sdl_surface_erase(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	int r = lua_tonumber(L, 2);
	int g = lua_tonumber(L, 3);
	int b = lua_tonumber(L, 4);
	SDL_FillRect(*s, NULL, SDL_MapRGB(screen->format, r, g, b));
	return 0;
}

static int sdl_surface_toscreen(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	int x = luaL_checknumber(L, 2);
	int y = luaL_checknumber(L, 3);
	if (s && *s)
	{
		sdlDrawImage(screen, *s, x, y);
	}
	return 0;
}

static int sdl_surface_merge(lua_State *L)
{
	SDL_Surface **dst = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	SDL_Surface **src = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 2);
	int x = luaL_checknumber(L, 3);
	int y = luaL_checknumber(L, 4);
	if (dst && *dst && src && *src)
	{
		sdlDrawImage(*dst, *src, x, y);
	}
	return 0;
}

static int sdl_surface_alpha(lua_State *L)
{
	SDL_Surface **s = (SDL_Surface**)auxiliar_checkclass(L, "sdl{surface}", 1);
	int a = luaL_checknumber(L, 2);
	SDL_SetAlpha(*s, SDL_SRCALPHA | SDL_RLEACCEL, (a < 0) ? 0 : (a > 255) ? 255 : a);
	return 0;
}

static int sdl_set_window_title(lua_State *L)
{
	const char *title = luaL_checkstring(L, 1);
	SDL_WM_SetCaption(title, NULL);
	return 0;
}

static const struct luaL_reg displaylib[] =
{
	{"fullscreen", sdl_fullscreen},
	{"size", sdl_screen_size},
	{"newFont", sdl_new_font},
	{"newSurface", sdl_new_surface},
	{"loadImage", sdl_load_image},
	{"setWindowTitle", sdl_set_window_title},
	{NULL, NULL},
};

static const struct luaL_reg sdl_surface_reg[] =
{
	{"__gc", sdl_free_surface},
	{"close", sdl_free_surface},
	{"erase", sdl_surface_erase},
	{"merge", sdl_surface_merge},
	{"toScreen", sdl_surface_toscreen},
	{"putChar", lua_display_char},
	{"drawString", sdl_surface_drawstring},
	{"alpha", sdl_surface_alpha},
	{NULL, NULL},
};

static const struct luaL_reg sdl_font_reg[] =
{
	{"__gc", sdl_free_font},
	{"close", sdl_free_font},
	{"size", sdl_font_size},
	{"height", sdl_font_height},
	{"lineSkip", sdl_font_lineskip},
	{NULL, NULL},
};

/******************************************************************
 ******************************************************************
 *                              RNG                               *
 ******************************************************************
 ******************************************************************/

static int rng_dice(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	int y = luaL_checknumber(L, 2);
	int i, res = 0;
	for (i = 0; i < x; i++)
		res += 1 + rand_div(y);
	lua_pushnumber(L, res);
	return 1;
}

static int rng_range(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	int y = luaL_checknumber(L, 2);
	lua_pushnumber(L, x + rand_div(1 + y - x));
	return 1;
}

static int rng_avg(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	int y = luaL_checknumber(L, 2);
	int nb = 2;
	double res = 0;
	int i;
	if (lua_isnumber(L, 3)) nb = luaL_checknumber(L, 3);
	for (i = 0; i < nb; i++)
		res += x + rand_div(1 + y - x);
	lua_pushnumber(L, res / nb);
	return 1;
}

static int rng_call(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	if (lua_isnumber(L, 2))
	{
		int y = luaL_checknumber(L, 2);
		lua_pushnumber(L, x + rand_div(1 + y - x));
	}
	else
	{
		lua_pushnumber(L, rand_div(x));
	}
	return 1;
}

static int rng_seed(lua_State *L)
{
	int seed = luaL_checknumber(L, 1);
	if (seed>=0)
		init_gen_rand(seed);
	else
		init_gen_rand(time(NULL));
	return 0;
}

static int rng_chance(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	lua_pushboolean(L, rand_div(x) == 0);
	return 1;
}

static int rng_percent(lua_State *L)
{
	int x = luaL_checknumber(L, 1);
	lua_pushboolean(L, rand_div(100) < x);
	return 1;
}

static const struct luaL_reg rnglib[] =
{
	{"__call", rng_call},
	{"range", rng_range},
	{"avg", rng_avg},
	{"dice", rng_dice},
	{"seed", rng_seed},
	{"chance", rng_chance},
	{"percent", rng_percent},
	{NULL, NULL},
};


/******************************************************************
 ******************************************************************
 *                             Line                               *
 ******************************************************************
 ******************************************************************/
typedef struct {
	int stepx;
	int stepy;
	int e;
	int deltax;
	int deltay;
	int origx;
	int origy;
	int destx;
	int desty;
} line_data;

/* ********** bresenham line drawing ********** */
int lua_line_init(lua_State *L)
{
	int xFrom = luaL_checknumber(L, 1);
	int yFrom = luaL_checknumber(L, 2);
	int xTo = luaL_checknumber(L, 3);
	int yTo = luaL_checknumber(L, 4);

	line_data *data = (line_data*)lua_newuserdata(L, sizeof(line_data));
	auxiliar_setclass(L, "line{core}", -1);

	data->origx=xFrom;
	data->origy=yFrom;
	data->destx=xTo;
	data->desty=yTo;
	data->deltax=xTo - xFrom;
	data->deltay=yTo - yFrom;
	if ( data->deltax > 0 ) {
		data->stepx=1;
	} else if ( data->deltax < 0 ){
		data->stepx=-1;
	} else data->stepx=0;
	if ( data->deltay > 0 ) {
		data->stepy=1;
	} else if ( data->deltay < 0 ){
		data->stepy=-1;
	} else data->stepy = 0;
	if ( data->stepx*data->deltax > data->stepy*data->deltay ) {
		data->e = data->stepx*data->deltax;
		data->deltax *= 2;
		data->deltay *= 2;
	} else {
		data->e = data->stepy*data->deltay;
		data->deltax *= 2;
		data->deltay *= 2;
	}

	return 1;
}

int lua_line_step(lua_State *L)
{
	line_data *data = (line_data*)auxiliar_checkclass(L, "line{core}", 1);

	if ( data->stepx*data->deltax > data->stepy*data->deltay ) {
		if ( data->origx == data->destx ) return 0;
		data->origx+=data->stepx;
		data->e -= data->stepy*data->deltay;
		if ( data->e < 0) {
			data->origy+=data->stepy;
			data->e+=data->stepx*data->deltax;
		}
	} else {
		if ( data->origy == data->desty ) return 0;
		data->origy+=data->stepy;
		data->e -= data->stepx*data->deltax;
		if ( data->e < 0) {
			data->origx+=data->stepx;
			data->e+=data->stepy*data->deltay;
		}
	}
	lua_pushnumber(L, data->origx);
	lua_pushnumber(L, data->origy);
	return 2;
}

int lua_free_line(lua_State *L)
{
	line_data *data = (line_data*)auxiliar_checkclass(L, "line{core}", 1);
	lua_pushnumber(L, 1);
	return 1;
}

static const struct luaL_reg linelib[] =
{
	{"new", lua_line_init},
	{NULL, NULL},
};

static const struct luaL_reg line_reg[] =
{
	{"__gc", lua_free_line},
	{"__call", lua_line_step},
	{NULL, NULL},
};

int luaopen_core(lua_State *L)
{
	auxiliar_newclass(L, "line{core}", line_reg);
	auxiliar_newclass(L, "fov{core}", fov_reg);
	auxiliar_newclass(L, "sdl{surface}", sdl_surface_reg);
	auxiliar_newclass(L, "sdl{font}", sdl_font_reg);
	luaL_openlib(L, "core.fov", fovlib, 0);
	luaL_openlib(L, "core.display", displaylib, 0);
	luaL_openlib(L, "core.mouse", mouselib, 0);
	luaL_openlib(L, "core.key", keylib, 0);
	luaL_openlib(L, "core.game", gamelib, 0);
	luaL_openlib(L, "rng", rnglib, 0);
	luaL_openlib(L, "line", linelib, 0);
	return 1;
}
