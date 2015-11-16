/*
	TE4 - T-Engine 4
	Copyright (C) 2009 - 2015 Nicolas Casalini

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Nicolas Casalini "DarkGod"
	darkgod@te4.org
*/
#ifndef _VEXTEXES_HPP_
#define _VEXTEXES_HPP_

extern "C" {
#include "tgl.h"
#include "useshader.h"
}

#include <vector>

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#include "glm/ext.hpp"

using namespace glm;
using namespace std;

typedef struct {
	vec2 pos;
	vec2 tex;
	vec4 color;
} vertex;

class Vertexes{
private:
	// static long next_id = 1;
	vector<long> ids;
	vector<vertex> list;
	
public:
	Vertexes(int size);

	int addQuad(
		float x1, float y1, float u1, float v1, 
		float x2, float y2, float u2, float v2, 
		float x3, float y3, float u3, float v3, 
		float x4, float y4, float u4, float v4, 
		float r, float g, float b, float a
	);
};

class DisplayObject {
private:
	int lua_ref;
public:
	bool changed = false;

	void setLuaRef(int ref) { lua_ref = ref; };
};

class DOVertexes : public DisplayObject{
private:
	Vertexes v;
	GLuint tex;
	shader_type *shader;

public:
	DOVertexes() : v(4) {
		tex = 0;
		shader = NULL;
	};

	void setTexture(GLuint tex) { this->tex = tex; };
	void setShader(shader_type *s) { shader = s; };
};

class DOContainer : public DisplayObject{
private:
	vector<DisplayObject*> dos;
public:
	DOContainer() {};

	void add(DisplayObject *dob);
	void remove(DisplayObject *dob);
};

#endif
