shader_type canvas_item;

// Tamanho do tile em pixels
uniform float tileSizeInPixels : hint_range(16.0, 64.0) = 32.0;

// Tamanho da textura atlas em pixels
uniform float textureAtlasTextureSizeInPixels = 128.0;

// Quantidade de texturas por linha na atlas (4x4 = 4)
uniform float textureAtlasTexturesWidth = 4.0;

// Dimensões do mapa em tiles
uniform float mapTilesCountX = 128.0;
uniform float mapTilesCountY = 128.0;

// Textura atlas - OBRIGATÓRIA
uniform sampler2D textureAtlas : hint_default_black, filter_nearest;

// Dados do mapa - Gerado dinamicamente
uniform sampler2D mapData : hint_default_black, filter_nearest;

// Uniformes de blend removidos (não utilizados)

vec2 getTilePos(vec2 uv) {
    // Garante que os UVs estão no range válido
    float u = clamp(uv.x, 0.0, 0.999);
    float v = clamp(uv.y, 0.0, 0.999);

    return vec2(floor(u * mapTilesCountX), floor(v * mapTilesCountY));
}

vec2 getPixelPosInTile(vec2 uv) {
    // Calcula posição do pixel dentro do tile atual
    float uvScaleX = uv.x * mapTilesCountX;
    float uvScaleY = uv.y * mapTilesCountY;

    float relativePosX = fract(uvScaleX) * tileSizeInPixels;
    float relativePosY = fract(uvScaleY) * tileSizeInPixels;

    return vec2(relativePosX, relativePosY);
}

float getTileId(vec2 pos) {
    // Verifica bounds
    if (pos.x < 0.0 || pos.x >= mapTilesCountX || pos.y < 0.0 || pos.y >= mapTilesCountY) {
        return 3.0; // Água como fallback
    }

    // Lê o valor do tile do mapData com coordenadas corrigidas
    vec2 mapUV = (pos + vec2(0.5)) / vec2(mapTilesCountX, mapTilesCountY);
    vec4 mapPixel = texture(mapData, mapUV);

    // Converte de volta para ID do tile (0-7)
    // Assumindo que você está salvando o ID como mapPixel.r * 255 / 7
    float tileId = floor(mapPixel.r * 7.0 + 0.5);
    return clamp(tileId, 0.0, 7.0);
}

vec2 getAtlasPixelPos(vec2 pixelPosInTile, float tileId) {
    // Calcula posição na atlas baseada no ID do tile
    float row = floor(tileId / textureAtlasTexturesWidth);
    float col = mod(tileId, textureAtlasTexturesWidth);

    // Adiciona pequeno offset para evitar bleeding entre tiles
    vec2 offset = vec2(0.5, 0.5);
    vec2 textureStartPos = vec2(col * tileSizeInPixels, row * tileSizeInPixels) + offset;

    // Clamp para evitar sampling fora do tile
    vec2 clampedPixelPos = clamp(pixelPosInTile, vec2(1.0), vec2(tileSizeInPixels - 1.0));

    return textureStartPos + clampedPixelPos;
}

vec4 getColorForCurrentPixel(float tileId, vec2 pixelPosInTile) {
    vec2 pixelPosAtlas = getAtlasPixelPos(pixelPosInTile, tileId);
    vec2 atlasUV = pixelPosAtlas / vec2(textureAtlasTextureSizeInPixels);

    // Clamp UV para garantir que não saia dos bounds
    atlasUV = clamp(atlasUV, vec2(0.0), vec2(1.0));

    vec4 color = texture(textureAtlas, atlasUV);

    // Se a cor for inválida, usa uma cor padrão baseada no tileId
    if (color.a < 0.1) {
        // Cores de fallback por ID (usando comparação aproximada de float)
        if (abs(tileId - 0.0) < 0.0001) color = vec4(0.2, 0.8, 0.2, 1.0); // Verde (grama)
        else if (abs(tileId - 1.0) < 0.0001) color = vec4(0.6, 0.4, 0.2, 1.0); // Marrom (terra)
        else if (abs(tileId - 2.0) < 0.0001) color = vec4(0.8, 0.8, 0.8, 1.0); // Cinza (pedra)
        else if (abs(tileId - 3.0) < 0.0001) color = vec4(0.2, 0.2, 0.8, 1.0); // Azul (água)
        else color = vec4(0.5, 0.5, 0.5, 1.0); // Cinza padrão
    }

    return color;
}

void fragment() {
    // Verifica se as texturas necessárias estão disponíveis
    vec4 atlasTest = texture(textureAtlas, vec2(0.0));
    vec4 mapDataTest = texture(mapData, vec2(0.0));

    // Debug: Se não há textureAtlas, mostra vermelho
    if (atlasTest == vec4(0.0, 0.0, 0.0, 0.0)) {
        COLOR = vec4(1.0, 0.0, 0.0, 1.0); // Vermelho = sem textureAtlas
    }
    // Debug: Se não há mapData, mostra azul
    else if (mapDataTest == vec4(0.0, 0.0, 0.0, 0.0)) {
        COLOR = vec4(0.0, 0.0, 1.0, 1.0); // Azul = sem mapData
    }
    else {
        // Processamento normal
        vec2 tile = getTilePos(UV);
        vec2 pixelPosInTile = getPixelPosInTile(UV);

        float tileIdSelf = getTileId(tile);
        vec4 colorSelf = getColorForCurrentPixel(tileIdSelf, pixelPosInTile);

        // Remove o blend que estava causando as grades visíveis
        COLOR = colorSelf;

        // Debug: Mostra o tile ID como cor se necessário (descomente para debug)
        // COLOR = vec4(tileIdSelf / 7.0, 0.0, 0.0, 1.0);
    }
}