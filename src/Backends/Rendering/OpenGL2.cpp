#include "../Rendering.h"

#include <stddef.h>
#include <stdlib.h>

#include <GL/glew.h>
#include "SDL.h"

#include "../../WindowsWrapper.h"

#include "../../Font.h"

typedef struct Backend_Surface
{
	GLuint texture_id;
	unsigned int width;
	unsigned int height;
	unsigned char *pixels;
} Backend_Surface;

typedef struct Backend_Glyph
{
	GLuint texture_id;
	unsigned int width;
	unsigned int height;
} Backend_Glyph;

static SDL_Window *window;
static SDL_GLContext context;
static GLuint framebuffer_id;

static Backend_Surface framebuffer_surface;

BOOL Backend_Init(SDL_Window *p_window)
{
	window = p_window;

	int screen_width, screen_height;
	SDL_GetWindowSize(window, &screen_width, &screen_height);

	context = SDL_GL_CreateContext(window);

	if (glewInit() != GLEW_OK)
		return FALSE;

	// Check for framebuffer object extension (is part of the core spec in OpenGL 3.0, but not 2.1)
	if (!GLEW_EXT_framebuffer_object)
		return FALSE;

//	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glOrtho(0.0, screen_width, 0.0, screen_height, 1.0, -1.0);

//	glMatrixMode(GL_PROJECTION);
//	glLoadIdentity();

	glEnable(GL_TEXTURE_2D);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	// Set up blank default texture (it seems to be black by default, which sucks for colour modulation)
	const unsigned char white_pixel[3] = {0xFF, 0xFF, 0xFF};
	glBindTexture(GL_TEXTURE_2D, 0);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 1, 1, 0, GL_RGB, GL_UNSIGNED_BYTE, white_pixel);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	// Set up framebuffer (used for surface-to-surface blitting)
	glGenFramebuffersEXT(1, &framebuffer_id);

	// Set up framebuffer screen texture (used for screen-to-surface blitting)
	glGenTextures(1, &framebuffer_surface.texture_id);
	glBindTexture(GL_TEXTURE_2D, framebuffer_surface.texture_id);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, screen_width, screen_height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	framebuffer_surface.width = screen_width;
	framebuffer_surface.height = screen_height;

	return TRUE;
}

void Backend_Deinit(void)
{
	glDeleteTextures(1, &framebuffer_surface.texture_id);
	glDeleteFramebuffersEXT(1, &framebuffer_id);
	SDL_GL_DeleteContext(context);
}

void Backend_DrawScreen(void)
{
	// Target actual screen, and not our framebuffer
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

	// Draw framebuffer to screen
	glPushMatrix();
	glLoadIdentity();

	glBindTexture(GL_TEXTURE_2D, framebuffer_surface.texture_id);

	glBegin(GL_QUADS);
		glColor3f(1.0f, 1.0f, 1.0f);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(-1.0f, -1.0f);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f(1.0f, -1.0f);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f(1.0f, 1.0f);
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f(-1.0f, 1.0f);
	glEnd();

	glPopMatrix();

	SDL_GL_SwapWindow(window);

	// According to https://www.khronos.org/opengl/wiki/Common_Mistakes#Swap_Buffers
	// the buffer should always be cleared
	glClear(GL_COLOR_BUFFER_BIT);

	// Switch back to our framebuffer
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer_id);
}

Backend_Surface* Backend_CreateSurface(unsigned int width, unsigned int height)
{
	Backend_Surface *surface = (Backend_Surface*)malloc(sizeof(Backend_Surface));

	if (surface == NULL)
		return NULL;

	glGenTextures(1, &surface->texture_id);
	glBindTexture(GL_TEXTURE_2D, surface->texture_id);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	surface->width = width;
	surface->height = height;

	return surface;
}

void Backend_FreeSurface(Backend_Surface *surface)
{
	glDeleteTextures(1, &surface->texture_id);
	free(surface);
}

unsigned char* Backend_Lock(Backend_Surface *surface, unsigned int *pitch)
{
	surface->pixels = (unsigned char*)malloc(surface->width * surface->height * 4);
	*pitch = surface->width * 4;
	return surface->pixels;
}

void Backend_Unlock(Backend_Surface *surface)
{
	glBindTexture(GL_TEXTURE_2D, surface->texture_id);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, surface->width, surface->height, GL_RGBA, GL_UNSIGNED_BYTE, surface->pixels);
	free(surface->pixels);
}

static void BlitCommon(Backend_Surface *source_surface, const RECT *rect, long x, long y, BOOL alpha_blend)
{
	glBindTexture(GL_TEXTURE_2D, source_surface->texture_id);

	glBegin(GL_QUADS);
		glColor3f(1.0f, 1.0f, 1.0f);
		glTexCoord2f((GLfloat)rect->left / (GLfloat)source_surface->width, (GLfloat)rect->top / (GLfloat)source_surface->height);
		glVertex2f((GLfloat)x, (GLfloat)y);
		glTexCoord2f((GLfloat)rect->right / (GLfloat)source_surface->width, (GLfloat)rect->top / (GLfloat)source_surface->height);
		glVertex2f((GLfloat)x + (rect->right - rect->left), (GLfloat)y);
		glTexCoord2f((GLfloat)rect->right / (GLfloat)source_surface->width, (GLfloat)rect->bottom / (GLfloat)source_surface->height);
		glVertex2f((GLfloat)x + (rect->right - rect->left), (GLfloat)y + (rect->bottom - rect->top));
		glTexCoord2f((GLfloat)rect->left / (GLfloat)source_surface->width, (GLfloat)rect->bottom / (GLfloat)source_surface->height);
		glVertex2f((GLfloat)x, (GLfloat)y + (rect->bottom - rect->top));
	glEnd();
}

void Backend_Blit(Backend_Surface *source_surface, const RECT *rect, Backend_Surface *destination_surface, long x, long y, BOOL alpha_blend)
{
	// Point our framebuffer to the destination texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, destination_surface->texture_id, 0);

	BlitCommon(source_surface, rect, x, y, alpha_blend);
}

void Backend_BlitToScreen(Backend_Surface *source_surface, const RECT *rect, long x, long y, BOOL alpha_blend)
{
	// Point our framebuffer to the screen texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, framebuffer_surface.texture_id, 0);

	BlitCommon(source_surface, rect, x, y, alpha_blend);
}

static void ColourFillCommon(const RECT *rect, unsigned char red, unsigned char green, unsigned char blue, unsigned char alpha)
{
	// Use blank default texture, for a solid colour-fill
	glBindTexture(GL_TEXTURE_2D, 0);

	glBegin(GL_QUADS);
		glColor4f(red / 255.0f, green / 255.0f, blue / 255.0f, alpha / 255.0f);
		glVertex2f((GLfloat)rect->left, (GLfloat)rect->top);
		glVertex2f((GLfloat)rect->right, (GLfloat)rect->top);
		glVertex2f((GLfloat)rect->right, (GLfloat)rect->bottom);
		glVertex2f((GLfloat)rect->left, (GLfloat)rect->bottom);
	glEnd();
}

void Backend_ColourFill(Backend_Surface *surface, const RECT *rect, unsigned char red, unsigned char green, unsigned char blue, unsigned char alpha)
{	
	// Point our framebuffer to the destination texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, surface->texture_id, 0);

	ColourFillCommon(rect, red, green, blue, alpha);
}

void Backend_ColourFillToScreen(const RECT *rect, unsigned char red, unsigned char green, unsigned char blue)
{
	// Point our framebuffer to the screen texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, framebuffer_surface.texture_id, 0);

	ColourFillCommon(rect, red, green, blue, 0xFF);
}

void Backend_ScreenToSurface(Backend_Surface *surface, const RECT *rect)
{
	// Point our framebuffer to the destination texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, surface->texture_id, 0);

	BlitCommon(&framebuffer_surface, rect, rect->left, rect->top, FALSE);
}

Backend_Glyph* Backend_LoadGlyph(const unsigned char *pixels, unsigned int width, unsigned int height, int pitch, unsigned short total_greys, unsigned char pixel_mode)
{
	Backend_Glyph *glyph = (Backend_Glyph*)malloc(sizeof(Backend_Glyph));

	if (glyph == NULL)
		return NULL;

	unsigned char *buffer = (unsigned char*)malloc(width * height * 4);

	switch (pixel_mode)
	{
		case FONT_PIXEL_MODE_GRAY:
			for (unsigned int y = 0; y < height; ++y)
			{
				const unsigned char *source_pointer = pixels + y * pitch;
				unsigned char *destination_pointer = buffer + y * width * 4;

				for (unsigned int x = 0; x < width; ++x)
				{
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = (unsigned char)(pow((double)*source_pointer++ / (total_greys - 1), 1.0 / 1.8) * 255.0);
				}
			}

			break;

		case FONT_PIXEL_MODE_MONO:
			for (unsigned int y = 0; y < height; ++y)
			{
				const unsigned char *source_pointer = pixels + y * pitch;
				unsigned char *destination_pointer = buffer + y * width * 4;

				for (unsigned int x = 0; x < width; ++x)
				{
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = 0xFF;
					*destination_pointer++ = *source_pointer++ ? 0xFF : 0;
				}
			}

			break;
	}

	glGenTextures(1, &glyph->texture_id);
	glBindTexture(GL_TEXTURE_2D, glyph->texture_id);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	glyph->width = width;
	glyph->height = height;

	free(buffer);

	return glyph;
}

void Backend_UnloadGlyph(Backend_Glyph *glyph)
{
	glDeleteTextures(1, &glyph->texture_id);
	free(glyph);
}

static void DrawGlyphCommon(Backend_Glyph *glyph, long x, long y, const unsigned char *colours)
{
	glBindTexture(GL_TEXTURE_2D, glyph->texture_id);

	glBegin(GL_QUADS);
		glColor3f(colours[0] / 255.0f, colours[1] / 255.0f, colours[2] / 255.0f);
		glTexCoord2f(0.0f, 0.0f);
		glVertex2f((GLfloat)x, (GLfloat)y);
		glTexCoord2f(1.0f, 0.0f);
		glVertex2f((GLfloat)x + glyph->width, (GLfloat)y);
		glTexCoord2f(1.0f, 1.0f);
		glVertex2f((GLfloat)x + glyph->width, (GLfloat)y + glyph->height);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f((GLfloat)x, (GLfloat)y + glyph->height);
	glEnd();
}

void Backend_DrawGlyph(Backend_Surface *surface, Backend_Glyph *glyph, long x, long y, const unsigned char *colours)
{
	// Point our framebuffer to the destination texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, surface->texture_id, 0);

	DrawGlyphCommon(glyph, x, y, colours);
}

void Backend_DrawGlyphToScreen(Backend_Glyph *glyph, long x, long y, const unsigned char *colours)
{
	// Point our framebuffer to the screen texture
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, framebuffer_surface.texture_id, 0);

	DrawGlyphCommon(glyph, x, y, colours);
}

void Backend_HandleDeviceLoss(void)
{
	// No problem for us
}

void Backend_HandleWindowResize(void)
{
	// No problem for us
}