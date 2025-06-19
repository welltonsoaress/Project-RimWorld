shader_type canvas_item;

// Tamanho do tile em pixels
uniform float tileSizeInPixels = 32.0;

// Tamanho da textura atlas em pixels
uniform float textureAtlasTextureSizeInPixels = 128.0;

// Quantidade de texturas por linha na atlas (4x4 = 4)
uniform float textureAtlasTexturesWidth = 4.0;

// Dimensões do mapa em tiles
uniform float mapTilesCountX = 128.0;
uniform float mapTilesCountY = 128.0;

// Textura atlas
uniform sampler2D textureAtlas;

// Dados do mapa
uniform sampler2D mapData;

// Tile blend texture
uniform sampler2D blendTexture;

// Quantidade de tiles na blend texture
uniform float blendTextureTiles = 4.0;

vec2 getTilePos(vec2 uv) {
    vec4 debugColor = vec4(0.0);  // Agora local
    float u = clamp(uv.x, 0.0, 1.0 - 1.0/mapTilesCountX);
    float v = clamp(uv.y, 0.0, 1.0 - 1.0/mapTilesCountY);
    if (u <= 0.0 || u >= 1.0 || v <= 0.0 || v >= 1.0) {
        debugColor = vec4(1.0, 0.0, 0.0, 1.0);  // Vermelho para UVs inválidos
        return vec2(-1.0, -1.0);
    }
    return vec2(floor(u * mapTilesCountX), floor(v * mapTilesCountY));
}

vec2 getPixelPosInTile(vec2 uv) {
    float uvScaleX = uv.x * (mapTilesCountX * tileSizeInPixels) / textureAtlasTextureSizeInPixels;
    float uvScaleY = uv.y * (mapTilesCountY * tileSizeInPixels) / textureAtlasTextureSizeInPixels;
    float relativePosX = mod(uvScaleX, tileSizeInPixels);
    float relativePosY = mod(uvScaleY, tileSizeInPixels);
    return vec2(relativePosX, relativePosY);
}

float getTileId(vec2 pos) {
    vec4 debugColor = vec4(0.0);  // Local
    if (pos.x >= 0.0 && pos.x < mapTilesCountX && pos.y >= 0.0 && pos.y < mapTilesCountY) {
        float tileRed = texelFetch(mapData, ivec2(pos), 0).r;
        float tileId = floor(tileRed * 7.0);
        if (tileId < 0.0 || tileId > 7.0) {
            debugColor = vec4(1.0, 0.0, 1.0, 1.0);  // Magenta para tileId inválido
            return 3.0;  // Fallback
        }
        return clamp(tileId, 0.0, 7.0);
    }
    return 3.0;  // Fallback para água
}

vec2 getAtlasPixelPos(vec2 pixelPosInTile, float tileId) {
    float row = floor(tileId / textureAtlasTexturesWidth);
    float col = mod(tileId, textureAtlasTexturesWidth);
    vec2 textureStartPos = vec2(col * tileSizeInPixels, row * tileSizeInPixels);
    return textureStartPos + pixelPosInTile;
}

vec4 getColorForCurrentPixel(float tileId, vec2 pixelPosInTile) {
    vec2 pixelPosAtlas = getAtlasPixelPos(pixelPosInTile, tileId) / vec2(textureAtlasTextureSizeInPixels);
    vec4 color = texture(textureAtlas, pixelPosAtlas);
    if (color.a < 0.1) {
        return vec4(0.0, 1.0, 0.0, 1.0);  // Verde para falha na textura
    }
    return color;
}

void fragment() {
    vec2 tile = getTilePos(UV);
    vec2 pixelPosInTile = getPixelPosInTile(UV);
    
    float tileIdSelf = getTileId(tile);
    vec4 colorSelf = getColorForCurrentPixel(tileIdSelf, pixelPosInTile);
    
    if (tile.x < 0.0 || tile.y < 0.0) {  // Verifica UVs inválidos
        COLOR = vec4(1.0, 0.0, 0.0, 1.0);  // Vermelho
    } else if (tileIdSelf == 3.0 && texelFetch(mapData, ivec2(tile), 0).r * 7.0 < 0.0) {  // Verifica tileId inválido
        COLOR = vec4(1.0, 0.0, 1.0, 1.0);  // Magenta
    } else if (abs(colorSelf.a - 0.0) < 0.0001) {
        COLOR = vec4(0.5, 0.5, 0.5, 1.0);  // Cinza como fallback
    } else {
        float halfTile = tileSizeInPixels / 2.0;
        float blendFactorX = smoothstep(0.0, halfTile, abs(halfTile - pixelPosInTile.x));
        float blendFactorY = smoothstep(0.0, halfTile, abs(halfTile - pixelPosInTile.y));
        vec4 colorFinal = colorSelf;
        COLOR = mix(colorFinal, vec4(0.5, 0.5, 0.5, 1.0), max(blendFactorX, blendFactorY));
    }
}